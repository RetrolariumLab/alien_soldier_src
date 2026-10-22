#!/usr/bin/env python3
"""Read a stage's scrolling background: the three maps that describe it.

Nothing in the cartridge holds a stage's tilemap as a tilemap. It is folded
three times, and `Tilemap_QueueColumnFromDescriptor` in
`src/rendering/tilemap_column_streaming.s` is the whole specification. Given a
world position it splits the coordinate and looks the answer up three times:

    lsr.w   #8,d2   ...  (TileCoarseLookupOffset)    ; X >> 8
    lsr.w   #5,d2   ...  (TileFineLookupOffset)      ; (X >> 5) & 7
    lsr.w   #2,d2   ...  (TilePatternOffset)         ; ((X >> 3) & 3) * 2

    move.b  (a1,d2.w),d4 / lsl.w #6,d4               ; a chunk index, times 64
    move.b  (a1,d2.w),d4 / lsl.w #5,d4               ; a pattern index, times 32
    move.w  (a1,d3.w),(a2)+                          ; the name-table word

So the three levels are:

  * a **pattern**: four by four name-table words, 32 bytes, 32x32 pixels. The
    renderer writes its four rows from `+$00`, `+$08`, `+$10` and `+$18`, so
    the rows are four words apart and the column is `((X >> 3) & 3) * 2`.
  * a **chunk**: eight by eight pattern indices, 64 bytes, 256x256 pixels.
    A coarse byte times 64 is a chunk, because a chunk is 64 bytes.
  * a **coarse map**: thirty-two by thirty-two chunk indices, 1024 bytes,
    8192x8192 pixels. Indexed `((Y >> 8) & $1F) * 32 + (X >> 8)`.

The three maps are not in the cartridge either. They are decompressed into RAM
at $FFFF4000, $FFFF6000 and $FFFF7000 by asset command 6, `LoadCompressedToRAM`,
and the streaming descriptor is four longwords naming exactly those addresses:

    Gfx_DefaultVRAMTransferParameters:  dc.l $FFFF7000, $FFFF6000, $FFFF4000, $4000

The descriptor is sixteen bytes and the row loop rewinds fourteen of them
(`suba.l #$E,a0`), leaving the last word for the transfer: a flag saying
whether to mirror the column into a RAM plane buffer, then the VDP plane base.

An asset list is a uniform eight-byte record -- `dc.w command`, `dc.l source`,
`dc.w destination` -- read by `LoadObjData` until a negative word, with the
command indexing `LoadObjDataHandlers`. A stage reaches its list through
`StageTableIndex`: `Stage_AssetLoaderOffsets` picks a loader, the loader may
call another loader first, and each `lea <List>(pc),a0` names one list. So a
stage's background is the RAM those lists leave behind, in order, which is
what `build_ram` reproduces.
"""

from __future__ import annotations

from contextlib import contextmanager
from contextvars import ContextVar
from functools import wraps
import hashlib
import os
import re
import stat
import sys
from dataclasses import dataclass
from pathlib import Path
from types import CodeType, MappingProxyType

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from unpack_data import unpack_data  # noqa: E402
from authoring import guarded_inventory  # noqa: E402


SOURCE_ROOT = Path("src")
STREAMING_SOURCE = Path("src/rendering/tilemap_column_streaming.s")
LOADER_TABLE = "Stage_AssetLoaderOffsets"
SHARED_LOADER = "Stage_LoadSharedMappings"

PATTERN_BYTES = 32  # 4x4 name-table words
CHUNK_BYTES = 64  # 8x8 pattern indices
COARSE_COLUMNS = 32
COARSE_ROWS = 32
COARSE_BYTES = COARSE_COLUMNS * COARSE_ROWS
PATTERN_PIXELS = 32
CHUNK_PIXELS = 256

RAM_BASE = 0xFFFF0000
RAM_SIZE = 0x10000
DECOMPRESS_TO_RAM = 6  # LoadObjDataHandlers[6] is LoadCompressedToRAM
# src/ram_addrs.inc: the first named thing above the coarse map.
TERRAIN_COLLISION_BUFFER = 0xFFFF7800

LABEL_LINE = re.compile(r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*):(?P<rest>.*)$")
DIRECTIVE = re.compile(r"^\s*(?P<kind>dc\.[bwl]|binclude)\s+(?P<body>[^;]+?)\s*(?:;.*)?$")
LEA_LIST = re.compile(r"^\s+lea\s+([A-Za-z_][A-Za-z0-9_]*)\(pc\),a0\s*(?:;.*)?$")
CALLS_LOADER = re.compile(r"^\s+bsr\.[wsl]\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:;.*)?$")
TABLE_ENTRY = re.compile(r"^\s*dc\.w\s+([A-Za-z_][A-Za-z0-9_]*)-" + SHARED_LOADER + r"\s*(?:;.*)?$")
DESCRIPTOR = re.compile(r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*):\s+dc\.l\s+(?P<body>[^;]+?)\s*(?:;.*)?$")


def parse_number(token):
    token = token.strip()
    if token.startswith("$"):
        return int(token[1:], 16)
    if token.startswith("-$"):
        return -int(token[2:], 16)
    return int(token)


def signed_word(value):
    return value - 0x10000 if value >= 0x8000 else value


@dataclass(frozen=True)
class AssetCommand:
    """One eight-byte record of an asset list."""

    command: int
    source: str
    destination: int  # sign-extended into the RAM mirror

    @property
    def ram_offset(self):
        return (RAM_BASE + (signed_word(self.destination) & 0xFFFF)) - RAM_BASE

    @property
    def to_ram(self):
        return self.command == DECOMPRESS_TO_RAM


@dataclass
class Descriptor:
    """The four longwords the column streamer reads."""

    name: str
    coarse: int
    chunks: int
    patterns: int
    mirror_to_plane_buffer: bool
    plane_base: int


@dataclass
class Tilemap:
    """A stage's three maps, as the RAM image the loaders leave behind."""

    name: str
    lists: tuple
    ram: bytes
    descriptor: Descriptor
    written: tuple = ()  # (list, payload, ram offset, length)
    y_offset: int = 0  # $1000 for the offset variant, bit 15 of the mode

    def region(self, base):
        """How far past one of the three bases the loaders wrote.

        A payload does not always land exactly on its base: several stages load
        their patterns at $FFFF4020, leaving pattern zero blank. So a write
        counts towards a region when it starts inside it, and a region runs to
        whichever base comes next -- with the coarse map running to
        TerrainCollisionBuffer, which `src/ram_addrs.inc` puts at $FFFF7800.
        """
        edges = sorted(
            {self.descriptor.patterns, self.descriptor.chunks, self.descriptor.coarse, TERRAIN_COLLISION_BUFFER}
        )
        limit = next((edge for edge in edges if edge > base), RAM_BASE + RAM_SIZE)
        at, end = base - RAM_BASE, limit - RAM_BASE
        return max((offset + length - at for _, _, offset, length in self.written if at <= offset < end), default=0)

    @property
    def chunks_defined(self):
        """Chunks the stage actually loaded; a chunk is 256 pixels wide."""
        return self.region(self.descriptor.chunks) // CHUNK_BYTES

    @property
    def patterns_defined(self):
        return self.region(self.descriptor.patterns) // PATTERN_BYTES

    def coarse_index(self, x, y):
        return self._coarse(x, y + self.y_offset)

    def chunk_index(self, x, y):
        return self._chunk(x, y + self.y_offset)

    def name_word(self, x, y):
        """The VDP name-table word the streamer would write for this pixel."""
        y += self.y_offset
        offset = self._chunk(x, y) * PATTERN_BYTES + ((y >> 3) & 3) * 8 + ((x >> 3) & 3) * 2
        at = self.descriptor.patterns - RAM_BASE + offset
        return (self.ram[at] << 8) | self.ram[at + 1]

    def _coarse(self, x, y):
        offset = ((y >> 8) & 0x1F) * COARSE_COLUMNS + ((x >> 8) & 0x1F)
        return self.ram[self.descriptor.coarse - RAM_BASE + offset]

    def _chunk(self, x, y):
        offset = self._coarse(x, y) * CHUNK_BYTES + ((y >> 5) & 7) * 8 + ((x >> 5) & 7)
        return self.ram[self.descriptor.chunks - RAM_BASE + offset]

    def defined(self, x, y):
        """Whether this position reads maps the stage actually loaded.

        The coarse map is shared between the two planes and addresses more
        chunks than either alone defines, so plane B routinely looks up a
        chunk that only plane A has. Reading it anyway produces noise that
        looks like art, which is worse than a hole, so a position whose chunk
        or pattern is past what was loaded is reported as absent.
        """
        y += self.y_offset
        if self._coarse(x, y) * CHUNK_BYTES >= self.region(self.descriptor.chunks):
            return False
        return self._chunk(x, y) * PATTERN_BYTES < self.region(self.descriptor.patterns)

    def used_coarse_columns(self):
        """How many coarse columns of row 0 are not chunk zero."""
        row = [self.coarse_index(column * CHUNK_PIXELS, 0) for column in range(COARSE_COLUMNS)]
        while row and row[-1] == 0:
            row.pop()
        return len(row)


_PARSED_OPERATION = ContextVar("original_source_parse_operation", default=None)
_PARSED_MAX_FILE, _PARSED_MAX_TOTAL, _PARSED_MAX_ENTRIES = 128 << 20, 512 << 20, 32768
_LISTING_MAX_FILE, _LISTING_MAX_TOTAL = 16 << 20, 64 << 20
_LISTING_MAX_KEYS, _LISTING_MAX_ROWS = 32, 1000000


class _UncachedInclude(Exception):
    """An include outside the captured owners keeps the legacy fresh path."""


class _OriginalSourceChanged(Exception):
    """Never let the parser's permissive directive handler swallow raw drift."""


def _same_parse_root(first, second):
    # Do not inspect sentinel arguments before the public caller can reject
    # its profile/types. In particular this performs no filesystem access.
    return first is second or (
        isinstance(first, Path) and isinstance(second, Path) and first.absolute() == second.absolute()
    )


def _check_parsed_budget(primary, readonly):
    combined = dict(primary)
    for path, row in readonly.items():
        if path in combined and combined[path] != row:
            raise ValueError("readonly staged ORIGINAL records conflict; no rebind")
        combined[path] = row
    if (
        len(combined) > _PARSED_MAX_ENTRIES
        or sum(row[1] for row in combined.values() if row[0] == "file") > _PARSED_MAX_TOTAL
    ):
        raise ValueError("combined parsed source operation exceeds its total byte/entry bound")


class _ParsedSourceOperation:
    def __init__(self, root):
        self.requested_root, self.root, self.pid = root, None, os.getpid()
        self.closed, self._facts, self._unsupported = False, None, False
        self._texts = None
        self._asset_lists, self._descriptors = None, None
        self._mapping_blocks, self._mapping_unsupported = None, False
        self._animation_scripts = None
        self._listing_row_cache, self._listing_row_anchors, self._listing_corrupt = {}, (), False
        self._owners, self._records = (), {}
        self._parent, self._readonly = None, None
        self._readonly_owners, self._readonly_records, self._budget_failed = (), {}, False

    def require_live(self, *, closing=False):
        primary = self if self._parent is None else self._parent
        if (
            self.closed
            or primary.closed
            or os.getpid() != self.pid
            or os.getpid() != primary.pid
            or _PARSED_OPERATION.get() is not primary
        ):
            raise ValueError("parsed source operation is closed or outside its owning scope")
        if self._parent is not None and (
            primary._readonly is None or primary._readonly["facts"].get(self.root) is not self
        ):
            raise ValueError("readonly staged facts are outside their explicit scope")
        if primary._budget_failed and not closing:
            raise ValueError("combined parsed source operation exceeds its total byte/entry bound")

    def matches(self, root):
        return isinstance(root, Path) and _same_parse_root(self.requested_root, root)

    def _listing_path(self, path):
        return (
            self._parent is None
            and type(path) is type(Path())
            and type(self.requested_root) is type(Path())
            and ".." not in path.parts
            and path.absolute().is_relative_to(self.requested_root.absolute())
        )

    @staticmethod
    def _listing_key(key):
        if (
            type(key) is not tuple
            or len(key) != 3
            or type(key[0]) is not str
            or re.fullmatch(r"[0-9a-f]{64}", key[0]) is None
            or type(key[1]) is not int
            or not 0 <= key[1] <= _LISTING_MAX_FILE
        ):
            return False
        policy = key[2]
        return (
            type(policy) is tuple
            and len(policy) == 4
            and type(policy[0]) is str
            and type(policy[1]) is int
            and type(policy[2]) is int
            and policy[2] >= 0
            and type(policy[3]) is CodeType
        )

    @staticmethod
    def _listing_rows_valid(rows):
        if type(rows) is not tuple or len(rows) > _LISTING_MAX_ROWS:
            return False
        previous = 0
        for row in rows:
            if (
                type(row) is not tuple
                or len(row) != 3
                or type(row[0]) is not int
                or not previous < row[0] < 1 << 64
                or type(row[1]) is not int
                or not 0 <= row[1] < 1 << 64
                or type(row[2]) is not bytes
                or not row[2]
            ):
                return False
            previous = row[0]
        return True

    def _check_listing_cache(self, *, closing=False):
        self.require_live(closing=closing)
        try:
            if (
                self._listing_corrupt is not False
                or type(self._listing_row_cache) is not dict
                or type(self._listing_row_anchors) is not tuple
                or len(self._listing_row_anchors) > _LISTING_MAX_KEYS
            ):
                raise ValueError("listing input cache state changed")
            expected, total, count = {}, 0, 0
            for anchor in self._listing_row_anchors:
                if type(anchor) is not tuple or len(anchor) != 2:
                    raise ValueError("listing input cache ORIGINAL anchor changed")
                key, rows = anchor
                if (
                    not self._listing_key(key)
                    or key in expected
                    or type(rows) is not tuple
                    or (closing and not self._listing_rows_valid(rows))
                ):
                    raise ValueError("listing input cache ORIGINAL rows changed")
                expected[key] = rows
                total, count = total + key[1], count + len(rows)
            if total > _LISTING_MAX_TOTAL or count > _LISTING_MAX_ROWS or len(self._listing_row_cache) != len(expected):
                raise ValueError("listing input cache inventory/bounds changed")
            for key, rows in self._listing_row_cache.items():
                if not self._listing_key(key) or key not in expected or rows is not expected[key]:
                    raise ValueError("listing input cache differs from its ORIGINAL immutable rows")
        except (ValueError, TypeError, AttributeError, IndexError) as error:
            self._listing_corrupt = True
            raise ValueError("parsed listing input cache is corrupt: " + str(error)) from error

    def listing_rows(self, path, raw, policy):
        """Share only fresh-byte-identified rows; no filesystem/PASS authority."""
        self._check_listing_cache()
        if not self._listing_path(path) or type(raw) is not bytes or len(raw) > _LISTING_MAX_FILE:
            return None
        import derive_profile_name_addresses as listing

        if policy is None or policy != listing._listing_parser_policy():
            return None
        key = (hashlib.sha256(raw).hexdigest(), len(raw), policy)
        if key in self._listing_row_cache:
            return self._listing_row_cache[key]
        if (
            len(self._listing_row_anchors) >= _LISTING_MAX_KEYS
            or sum(item[0][1] for item in self._listing_row_anchors) + len(raw) > _LISTING_MAX_TOTAL
        ):
            return None
        try:
            rows = tuple(listing._parse_listing_rows(raw))
        except ValueError:
            # Eager decoding must not move a later malformed field ahead of
            # the legacy loop's earlier CURRENT-ROM mismatch or bounds error.
            # No partial input facts are admitted; stream the genuine old path.
            return None
        if (
            not self._listing_rows_valid(rows)
            or sum(len(item[1]) for item in self._listing_row_anchors) + len(rows) > _LISTING_MAX_ROWS
            or policy != listing._listing_parser_policy()
        ):
            return None
        # Exact built-in tuples/ints/bytes are immutable. Retain their ORIGINAL
        # identities independently, not a mirror's replaceable self-digest.
        self._listing_row_cache[key] = rows
        self._listing_row_anchors = (*self._listing_row_anchors, (key, rows))
        self._check_listing_cache()
        return rows

    def _capture(self):
        if self._parent is not None:
            raise ValueError("readonly staged facts cannot recapture their ORIGINAL inputs")
        self.root = self.requested_root.absolute()
        owners, total, count = [], 0, 0
        for name in ("src", "data"):
            owner = self.root / name
            records = guarded_inventory.capture(
                owner, max_file=_PARSED_MAX_FILE, max_total=_PARSED_MAX_TOTAL, max_entries=_PARSED_MAX_ENTRIES
            )
            # Store immutable originals, not a mutable self-reported digest.
            frozen = tuple(
                (relative, row["kind"], row.get("bytes"), row.get("sha256")) for relative, row in records.items()
            )
            owners.append((owner, frozen))
            self._owners = tuple(owners)
            for relative, kind, size, digest in frozen:
                self._records[owner / relative] = (kind, size, digest)
                count += 1
                if kind == "file":
                    total += size
                if total > _PARSED_MAX_TOTAL or count > _PARSED_MAX_ENTRIES:
                    self._budget_failed = True
                    raise ValueError("parsed source operation exceeds its total byte/entry bound")
            try:
                _check_parsed_budget(self._records, self._readonly_records)
            except ValueError:
                self._budget_failed = True
                raise

    def _readonly_tree(self, tree):
        self.require_live()
        registry = self._readonly
        if tree in registry["facts"]:
            return registry["facts"][tree]
        guarded_inventory._owner(tree)  # Check current ancestry, not a new census/hash authority.
        prefix = tree.relative_to(registry["owner"]).as_posix()
        rows = registry["rows"]
        for relative in (prefix.split("/", 1)[0], prefix):
            if dict(rows.get(relative, ())) != {"kind": "directory"}:
                raise ValueError("readonly staged tree is absent from its ORIGINAL owner census")
        owners, records = [], {}
        for name in ("src", "data"):
            base = prefix + "/" + name
            if dict(rows.get(base, ())) != {"kind": "directory"}:
                raise ValueError("readonly staged src/data is absent from its ORIGINAL owner census")
            selected = {
                relative[len(base) + 1 :]: dict(fields)
                for relative, fields in rows.items()
                if relative.startswith(base + "/")
            }
            guarded_inventory._frozen_children(selected, _PARSED_MAX_FILE, _PARSED_MAX_ENTRIES)
            frozen = tuple(
                (relative, row["kind"], row.get("bytes"), row.get("sha256"))
                for relative, row in sorted(selected.items())
            )
            owner = tree / name
            owners.append((owner, frozen))
            records[owner] = ("directory", None, None)
            records.update({owner / relative: (kind, size, digest) for relative, kind, size, digest in frozen})
        retained_owners, retained_records = dict(self._readonly_owners), dict(self._readonly_records)
        for owner, frozen in owners:
            if owner in retained_owners and retained_owners[owner] != frozen:
                raise ValueError("readonly staged ORIGINAL census conflicts; no rebind")
            retained_owners[owner] = frozen
        for path, row in records.items():
            if path in retained_records and retained_records[path] != row:
                raise ValueError("readonly staged ORIGINAL records conflict; no rebind")
            retained_records[path] = row
        _check_parsed_budget(self._records, retained_records)
        child = _ParsedSourceOperation(tree)
        child._parent, child.root = self, tree
        child._owners, child._records = tuple(owners), records
        # Publish only after every row, bound and cross-scope anchor has passed.
        self._readonly_owners, self._readonly_records = tuple(retained_owners.items()), retained_records
        registry["facts"][tree] = child
        return child

    def _bytes(self, path):
        try:
            relative = path.relative_to(self.root)
        except ValueError:
            raise _UncachedInclude() from None
        if not relative.parts or relative.parts[0] not in {"src", "data"} or ".." in relative.parts:
            raise _UncachedInclude()
        original = self._records.get(path)
        if original is None:
            raise FileNotFoundError(str(path))  # Legacy missing binclude is ignored.
        kind, size, digest = original
        if kind != "file":
            raise IsADirectoryError(str(path))
        try:
            before = guarded_inventory._checked_stat(path)
            guarded_inventory._file_bounds(before, _PARSED_MAX_FILE)
            with path.open("rb") as stream:
                opened = os.fstat(stream.fileno())
                if guarded_inventory._identity(before) != guarded_inventory._identity(opened):
                    raise ValueError("source identity changed before its read")
                body = stream.read(size + 1)
                if not guarded_inventory._same_identity(opened, os.fstat(stream.fileno())):
                    raise ValueError("source identity changed during its read")
            if not guarded_inventory._same_identity(before, guarded_inventory._checked_stat(path)):
                raise ValueError("source identity changed after its read")
            if len(body) != size or hashlib.sha256(body).hexdigest() != digest:
                raise ValueError("source bytes differ from their ORIGINAL capture")
            return body
        except (OSError, ValueError) as error:
            raise _OriginalSourceChanged("parsed source ORIGINAL input changed: " + str(path)) from error

    def _text(self, path):
        # Path.read_text uses universal newlines, not only UTF-8 decoding.
        return self._bytes(path).decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")

    def texts(self):
        self.require_live()
        if self._texts is None:
            if not self._owners:
                self._capture()
            paths = sorted(
                path for path in self._records if path.is_relative_to(self.root / SOURCE_ROOT) and path.match("*.s")
            )
            try:
                self._texts = tuple((path, self._text(path)) for path in paths)
            except _OriginalSourceChanged as error:
                raise ValueError(str(error)) from error
        return self._texts

    def blocks(self):
        self.require_live()
        if self._unsupported:
            return _parse_labelled_blocks(self.requested_root)
        if self._facts is None:
            if not self._owners:
                self._capture()
            try:
                facts = _parse_labelled_blocks(self.root, original=self)
            except _UncachedInclude:
                self._unsupported = True
                return _parse_labelled_blocks(self.requested_root)
            except _OriginalSourceChanged as error:
                raise ValueError(str(error)) from error
            self._facts = tuple(MappingProxyType(dict(value)) for value in facts)
        return tuple(dict(value) for value in self._facts)

    def _owns_bodies(self, bodies):
        self.require_live()
        if self._unsupported or self._facts is None or type(bodies) is not dict:
            return False
        original = self._facts[1]
        return len(bodies) == len(original) and all(
            type(name) is str and name == expected_name and lines is expected_lines
            for (name, lines), (expected_name, expected_lines) in zip(bodies.items(), original.items())
        )

    def asset_lists(self, bodies):
        if not self._owns_bodies(bodies):
            return _parse_asset_lists(bodies)
        if self._asset_lists is None:
            # Preserve the caller's exact legacy iteration/callback semantics.
            # A callback-mutated supplied dict must not become cached authority.
            result = _parse_asset_lists(bodies)
            if self._owns_bodies(bodies):
                self._asset_lists = tuple(result.items())
            return result
        return dict(self._asset_lists)

    def descriptors(self):
        self.require_live()
        if self._descriptors is None:
            result = _parse_descriptors(self.texts())
            self._descriptors = tuple(
                (item.name, item.coarse, item.chunks, item.patterns, item.mirror_to_plane_buffer, item.plane_base)
                for item in result.values()
            )
            return result
        # Descriptor is deliberately mutable in its public API. Retain only
        # scalar original facts, never an instance a caller can subsequently edit.
        return {row[0]: Descriptor(*row) for row in self._descriptors}

    def animation_scripts(self):
        """Symbolic ORIGINAL input pairs only, never a model/pointer verdict."""
        self.require_live()
        from authoring import object_sprite_model as sprites

        if self._animation_scripts is None:
            parsed = sprites._parse_animation_scripts(self.requested_root, original=self)
            self._animation_scripts = tuple(
                (name, tuple((frame.mapping, frame.duration) for frame in frames)) for name, frames in parsed.items()
            )
        # Even frozen dataclasses can be changed by object.__setattr__.
        # No public dict, tuple or Frame is retained as original authority.
        return {
            name: tuple(sprites.Frame(mapping, duration) for mapping, duration in frames)
            for name, frames in self._animation_scripts
        }

    def mapping_blocks(self):
        """Immutable ORIGINAL parsed pieces only; no model/pointer/verifier result."""
        self.require_live()
        from authoring import sprite_mapping_model as sprites

        if self._mapping_unsupported:
            return sprites._parse_read_blocks(self.requested_root)
        if self._mapping_blocks is None:
            if not self._owners:
                self._capture()
            try:
                blocks, skipped = sprites._parse_read_blocks(self.root, original=self)
            except _UncachedInclude:
                # An external payload retains the complete legacy fresh path.
                # Do not publish the earlier partial ORIGINAL parse as a cache.
                self._mapping_unsupported = True
                return sprites._parse_read_blocks(self.requested_root)
            except _OriginalSourceChanged as error:
                raise ValueError(str(error)) from error
            self._mapping_blocks = (
                tuple(
                    (
                        block.name,
                        block.source,
                        block.storage,
                        block.payload,
                        block.data,
                        tuple(
                            (
                                mapping.block,
                                mapping.offset,
                                tuple(
                                    (
                                        piece.attributes,
                                        piece.size,
                                        piece.link,
                                        piece.y,
                                        piece.x,
                                        piece.art,
                                        piece.art_addend,
                                    )
                                    for piece in mapping.pieces
                                ),
                            )
                            for mapping in block.mappings
                        ),
                    )
                    for block in blocks
                ),
                tuple(skipped.items()),
            )
        blocks, skipped = self._mapping_blocks
        # Public mappings/blocks are mutable; even their frozen piece objects
        # must be new, rather than references held by any prior public result.
        return (
            [
                sprites.MappingBlock(
                    name,
                    source,
                    storage,
                    payload,
                    data,
                    tuple(
                        sprites.SpriteMapping(block, offset, tuple(sprites.SpritePiece(*piece) for piece in pieces))
                        for block, offset, pieces in mappings
                    ),
                )
                for name, source, storage, payload, data, mappings in blocks
            ],
            dict(skipped),
        )

    def close(self):
        self.require_live(closing=True)
        cache_error = None
        try:
            self._check_listing_cache(closing=True)
        except ValueError as error:
            cache_error = error
        # Staged originals close LAST, including after outer source-session callbacks.
        raw_failed = False
        try:
            for owner, frozen in (*self._owners, *self._readonly_owners):
                records = {
                    relative: (
                        {"kind": "directory"}
                        if kind == "directory"
                        else {"kind": "file", "bytes": size, "sha256": digest}
                    )
                    for relative, kind, size, digest in frozen
                }
                guarded_inventory.close(owner, records, max_file=_PARSED_MAX_FILE, max_entries=_PARSED_MAX_ENTRIES)
        except BaseException:
            raw_failed = True
            raise
        finally:
            try:
                self._check_listing_cache(closing=True)
            except ValueError:
                if cache_error is None and not raw_failed:
                    raise
        if cache_error is not None:
            raise cache_error


def _listing_operation(path):
    """Exact primary-root lookup; foreign paths retain their fresh legacy path."""
    active = _PARSED_OPERATION.get()
    if active is None:
        return None
    active._check_listing_cache()
    return active if active._listing_path(path) else None


def _readonly_staged_facts(root, owner, frozen, labels):
    """Freeze a genuine owner census now; enable exact readonly trees only in `with`.

    Only already-captured src/data facts are shared. Unused trees remain lazy;
    staged config, documents, receipts and later assembly outputs are not locked.
    """
    if type(frozen) is not dict or len(frozen) > _PARSED_MAX_ENTRIES:
        raise ValueError("readonly staged ORIGINAL owner census has an invalid typed bound")
    captured = {}
    for relative, row in frozen.items():
        if (
            type(relative) is not str
            or type(row) is not dict
            or any(
                type(key) is not str
                or not (type(value) is str or type(value) is int or type(value) is bool or value is None)
                for key, value in row.items()
            )
        ):
            raise ValueError("readonly staged ORIGINAL census is not plain immutable data")
        captured[relative] = tuple(row.items())
    originals = MappingProxyType(captured)

    @contextmanager
    def activate():
        active = _PARSED_OPERATION.get()
        if active is None or not active.matches(root):
            raise ValueError("readonly staged facts require their exact primary root scope")
        active.require_live()
        if active._readonly is not None:
            raise ValueError("readonly staged fact scopes cannot overlap")
        if (
            not isinstance(owner, Path)
            or ".." in owner.parts
            or not owner.absolute().is_relative_to(root.absolute() / "build")
            or type(labels) is not tuple
            or not 1 <= len(labels) <= 21
            or any(type(label) is not str or not re.fullmatch(r"[A-Za-z0-9_]+", label) for label in labels)
            or len({label.casefold() for label in labels}) != len(labels)
        ):
            raise ValueError("readonly staged trees require fixed canonical owner/label/tree paths")
        registry = {
            "owner": owner.absolute(),
            "rows": originals,
            "trees": {owner.absolute() / label / "tree" for label in labels},
            "facts": {},
        }
        active._readonly = registry
        try:
            yield
        finally:
            valid = active._readonly is registry
            for child in registry["facts"].values():
                child.closed = True
                child._facts, child._texts, child._asset_lists, child._descriptors = None, None, None, None
                child._mapping_blocks, child._mapping_unsupported = None, False
                child._animation_scripts = None
            active._readonly = None
            if not valid:
                raise ValueError("readonly staged facts scope was replaced during use")

    return activate()


def _read_operation(root, *, create=True):
    active = _PARSED_OPERATION.get()
    if active is not None:
        if active.matches(root):
            active.require_live()
            if create and not active._owners:
                # A source-only model tree is a valid legacy input, but not a
                # complete preservation corpus. Do not invent missing owners
                # or reuse parsed facts from it. Unsafe existing nodes still
                # refuse; an already admitted corpus can NEVER fall back.
                missing = False
                for name in ("src", "data"):
                    try:
                        info = guarded_inventory._checked_stat(root / name)
                    except FileNotFoundError:
                        missing = True
                    else:
                        if not stat.S_ISDIR(info.st_mode):
                            raise ValueError("parsed source owner is not a directory")
                if missing:
                    return None
            return active
        if active._readonly is not None and isinstance(root, Path) and root.absolute() in active._readonly["trees"]:
            if not create and root.absolute() not in active._readonly["facts"]:
                return None
            return active._readonly_tree(root.absolute())
    return None


@contextmanager
def parsed_operation(root):
    """Share only ORIGINAL parsed facts in one lazy, exactly rooted operation.

    Other/staged roots use the fresh parser unless explicitly readonly-listed.
    Raw originals and complete
    src/data directory censuses close after all callbacks, including failures.
    No model, recipe, verifier result or persisted qualification is cached.
    """
    active = _PARSED_OPERATION.get()
    if active is not None:
        active.require_live()
        if not _same_parse_root(active.requested_root, root):
            raise ValueError("parsed source operation cannot mix preservation roots")
        yield active
        return
    active = _ParsedSourceOperation(root)
    token = _PARSED_OPERATION.set(active)
    try:
        yield active
    finally:
        try:
            active.close()
        finally:
            active.closed = True
            _PARSED_OPERATION.reset(token)


@contextmanager
def parsed_read_phase(root):
    """Scope a pure read when idle; never adopt an active foreign root.

    Within an existing operation, its exact-root readers keep their original
    input scope and foreign readers keep the genuine fresh legacy path. This
    grants no staged readonly capability and does not suspend any raw closer.
    """
    active = _PARSED_OPERATION.get()
    if active is not None:
        active.require_live()
        yield active
    else:
        with parsed_operation(root) as operation:
            yield operation


def with_parsed_operation(function):
    """Wrap a genuine root-first API without changing its early refusals."""

    @wraps(function)
    def wrapped(*args, **kwargs):
        if not args and "root" not in kwargs:
            return function(*args, **kwargs)
        root = args[0] if args else kwargs["root"]
        with parsed_operation(root):
            return function(*args, **kwargs)

    return wrapped


def labelled_blocks(root):
    """Every labelled run of directives, plus every label's raw source lines."""
    active = _read_operation(root)
    if active is not None:
        return active.blocks()
    return _parse_labelled_blocks(root)


def source_texts(root):
    """Yield ordered original universal-newline texts, never parsed verdicts."""
    active = _read_operation(root)
    if active is not None:
        for path, text in active.texts():
            # Preserve the caller's relative/absolute Path wire spelling.
            yield root / path.relative_to(active.root), text
        return
    for path in sorted(root.joinpath(SOURCE_ROOT).rglob("*.s")):
        yield path, path.read_text(encoding="utf-8")


def _parse_labelled_blocks(root, original=None):
    data = {}
    bodies = {}
    sources = (
        ((path, path.read_text(encoding="utf-8")) for path in sorted(root.joinpath(SOURCE_ROOT).rglob("*.s")))
        if original is None
        else original.texts()
    )
    for path, text in sources:
        name = None
        kind = None
        tokens = []
        lines = []

        def flush():
            if name is None:
                return
            bodies[name] = tuple(lines)
            if not tokens:
                return
            try:
                if kind == "binclude":
                    path = root / tokens[0].strip('"')
                    data[name] = path.read_bytes() if original is None else original._bytes(path)
                elif kind == "dc.b":
                    data[name] = bytes(parse_number(token) & 0xFF for token in tokens)
                elif kind == "dc.w":
                    data[name] = tuple(parse_number(token) for token in tokens)
            except (ValueError, OSError):
                pass

        for line in text.split("\n"):
            head = LABEL_LINE.match(line)
            if head:
                flush()
                name, kind, tokens, lines = head.group("name"), None, [], []
                line = head.group("rest")
            if name is None:
                continue
            lines.append(line)
            directive = DIRECTIVE.match(line)
            if directive is None:
                continue
            if kind is None:
                kind = directive.group("kind")
            elif kind != directive.group("kind"):
                continue
            tokens.extend(token.strip() for token in directive.group("body").split(","))
        flush()
    return data, bodies


def read_asset_list(name, lines):
    """One asset list, or None when the label is not one.

    A record is `dc.w command`, `dc.l source`, `dc.w destination`, and the list
    ends at a negative word. Anything else means this label is something other
    than an asset list, and the caller moves on rather than guessing.
    """
    tokens = []
    for line in lines:
        directive = DIRECTIVE.match(line)
        if directive is None:
            if line.strip() and not line.strip().startswith(";"):
                return None
            continue
        for token in directive.group("body").split(","):
            tokens.append((directive.group("kind"), token.strip()))
    commands = []
    at = 0
    while at < len(tokens):
        kind, token = tokens[at]
        if kind != "dc.w":
            return None
        try:
            value = parse_number(token)
        except ValueError:
            return None
        if value & 0x8000:
            return commands if commands and at + 1 == len(tokens) else None
        if value >= len(LOAD_HANDLERS) or at + 2 >= len(tokens):
            return None
        if tokens[at + 1][0] != "dc.l" or tokens[at + 2][0] != "dc.w":
            return None
        try:
            destination = parse_number(tokens[at + 2][1])
        except ValueError:
            return None
        commands.append(AssetCommand(value, tokens[at + 1][1], destination))
        at += 3
    return None


LOAD_HANDLERS = (
    "LoadFuncToRAM",
    "Gfx_LoadDataToVRAM",
    "Gfx_LoadAndDecompTiles",
    "Gfx_LoadCompressedGfx",
    "LoadFuncToRAM",
    "Gfx_LoadDataToVRAM",
    "LoadCompressedToRAM",
    "LoadCompressedToVRAM",
)


def read_asset_lists(root, bodies=None):
    """Every label whose body reads as a whole asset list."""
    if bodies is None:
        _, bodies = labelled_blocks(root)
    active = _read_operation(root, create=False)
    if active is not None:
        return active.asset_lists(bodies)
    return _parse_asset_lists(bodies)


def _parse_asset_lists(bodies):
    lists = {}
    for name, lines in bodies.items():
        commands = read_asset_list(name, lines)
        if commands:
            lists[name] = tuple(commands)
    return lists


def loader_lists(root, bodies, lists, loader, seen=None):
    """The asset lists a loader plays, following the loader it calls first."""
    seen = seen if seen is not None else set()
    if loader in seen or loader not in bodies:
        return []
    seen.add(loader)
    found = []
    for line in bodies[loader]:
        call = CALLS_LOADER.match(line)
        if call:
            found.extend(loader_lists(root, bodies, lists, call.group(1), seen))
            continue
        named = LEA_LIST.match(line)
        if named and named.group(1) in lists:
            found.append(named.group(1))
    return found


def stage_loaders(root, data):
    """StageTableIndex to the loader routine it selects."""
    entries = []
    for path in sorted(root.joinpath(SOURCE_ROOT).rglob("*.s")):
        text = path.read_text(encoding="utf-8").split("\n")
        for index, line in enumerate(text):
            if not line.startswith(LOADER_TABLE + ":"):
                continue
            for follow in text[index:]:
                match = TABLE_ENTRY.match(follow.replace(LOADER_TABLE + ":", " " * 8))
                if match:
                    entries.append(match.group(1))
                elif follow.strip() and not follow.strip().startswith(";"):
                    if entries:
                        return entries
    return entries


def read_descriptors(root):
    """Every sixteen-byte streaming descriptor in the tree."""
    active = _read_operation(root)
    if active is not None and not active._unsupported:
        return active.descriptors()
    sources = ((path, path.read_text(encoding="utf-8")) for path in sorted(root.joinpath(SOURCE_ROOT).rglob("*.s")))
    return _parse_descriptors(sources)


def _parse_descriptors(sources):
    found = {}
    for path, text in sources:
        for line in text.split("\n"):
            match = DESCRIPTOR.match(line)
            if match is None or "VRAMTransferParameters" not in match.group("name"):
                continue
            values = [parse_number(token) for token in match.group("body").split(",")]
            if len(values) != 4:
                continue
            found[match.group("name")] = Descriptor(
                match.group("name"), values[0], values[1], values[2], bool(values[3] >> 16), values[3] & 0xFFFF
            )
    return found


def decompress(payload):
    """One LoadCompressedToRAM payload: a size word, then LZSS."""
    out, error = unpack_data(payload)
    if out is None:
        raise ValueError(error)
    return bytes(out)


def build_ram(root, list_names, lists, data):
    """Play the lists' decompress-to-RAM commands into one RAM image."""
    ram = bytearray(RAM_SIZE)
    written = []
    for name in list_names:
        for command in lists[name]:
            if not command.to_ram or command.source not in data:
                continue
            payload = data[command.source]
            if not isinstance(payload, bytes):
                continue
            body = decompress(payload)
            at = command.ram_offset
            ram[at : at + len(body)] = body
            written.append((name, command.source, at, len(body)))
    return bytes(ram), written


def stage_tilemaps(root, descriptor_name="Gfx_DefaultVRAMTransferParameters"):
    """Every stage table index, as the tilemap its asset lists leave in RAM."""
    data, bodies = labelled_blocks(root)
    lists = read_asset_lists(root, bodies)
    descriptor = read_descriptors(root)[descriptor_name]
    found = []
    for index, loader in enumerate(stage_loaders(root, data)):
        # Stage_LoadAssetsForCurrentTableIndex plays the shared list first.
        names = loader_lists(root, bodies, lists, SHARED_LOADER) + loader_lists(root, bodies, lists, loader)
        ram, written = build_ram(root, names, lists, data)
        found.append(Tilemap("StageTableIndex%02d" % index, tuple(names), ram, descriptor, tuple(written)))
    return found


def survey(root):
    data, bodies = labelled_blocks(root)
    lists = read_asset_lists(root, bodies)
    loaders = stage_loaders(root, data)
    to_ram = [command for commands in lists.values() for command in commands if command.to_ram]
    payloads = {command.source for command in to_ram}
    decoded = 0
    sizes = {}
    for source in sorted(payloads):
        if source in data and isinstance(data[source], bytes):
            sizes[source] = len(decompress(data[source]))
            decoded += 1
    return {
        "asset_lists": len(lists),
        "asset_commands": sum(len(commands) for commands in lists.values()),
        "decompress_to_ram": len(to_ram),
        "ram_payloads": len(payloads),
        "ram_payloads_decoded": decoded,
        "stage_table_entries": len(loaders),
        "descriptors": len(read_descriptors(root)),
        "coarse_maps_of_1024": sum(1 for size in sizes.values() if size == COARSE_BYTES),
    }


# The two planes
#
# A stage draws two scrolling planes, and which maps each reads is chosen by
# its configuration record rather than fixed. `Stage_UpdateGameplayEntry` in
# `src/stages/gameplay_entry_states.s` reads StagePlaneAEntryMode and
# StagePlaneBEntryMode and does the same thing with each:
#
#     move.w  (StagePlaneAEntryMode).w,d0
#     bne.s   ..._Rows                      ; mode 0 is a constant fill
#     ...
#     bpl.s   ..._DirectRows                ; bit 15 picks the offset variant
#     andi.w  #$7FFF,d0
#     lea     Stage_EntryPrimaryPlaneVRAMParameterPointers(pc),a0
#     move.l  -4(a0,d0.w),(TilemapTransferBase).w
#
# so the mode is a byte offset into a table of descriptor pointers, biased by
# four: mode 4 is the first entry, mode 8 the second. Mode 0 means the plane is
# filled with one name-table word and reads no map at all, because the caller
# clears TilemapRowXOrFillWord before Tilemap_QueueNextConstantRow.
#
# Bit 15 is not a mirror despite the routine's name. What
# Tilemap_MirrorOffsetRowAndQueueScrollingRow actually does is
# `subi.w #$1000,d1` before negating, so it reads the same maps $1000 pixels
# further down.
#
# The descriptor's last word is the plane's VRAM address in the form the VDP
# write command takes: $4000 for plane A and $6000 for plane B, which are
# $C000 and $E000 once the command bits are removed - exactly what registers 2
# and 4 are set to in Gfx_GameVDPRegisterValues.

PLANE_A_TABLE = "Stage_EntryPrimaryPlaneVRAMParameterPointers"
PLANE_B_TABLE = "Stage_EntrySecondaryPlaneVRAMParameterPointers"
ENTRY_STATES_SOURCE = Path("src/stages/gameplay_entry_states.s")
MODE_BIAS = 4  # -4(a0,d0.w): mode 4 is the first entry
OFFSET_VARIANT = 0x8000  # bit 15 reads the maps $1000 further down
OFFSET_VARIANT_Y = 0x1000
CONSTANT_FILL_MODE = 0
# Gfx_GameVDPRegisterValues sets register 7 to $10: palette line 1, colour 0.
BACKDROP_REGISTER_VALUE = 0x10
POINTER_ENTRY = re.compile(r"^\s*dc\.l\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:;.*)?$")


def read_plane_tables(root):
    """The descriptor each plane entry mode selects, in table order."""
    lines = (root / ENTRY_STATES_SOURCE).read_text(encoding="utf-8").split("\n")
    tables = {}
    current = None
    for line in lines:
        head = LABEL_LINE.match(line)
        if head:
            name = head.group("name")
            current = (
                name
                if name in (PLANE_A_TABLE, PLANE_B_TABLE)
                else (current if not head.group("rest").strip() and current else None)
            )
            if name in (PLANE_A_TABLE, PLANE_B_TABLE):
                tables[name] = []
            line = head.group("rest")
        if current is None:
            continue
        entry = POINTER_ENTRY.match(line)
        if entry:
            tables[current].append(entry.group(1))
        elif line.strip() and not line.strip().startswith(";"):
            current = None
    return tables


def plane_descriptor(mode, table, *, offset_variant=True):
    """What a plane entry mode selects: a descriptor name and a map Y offset.

    Returns (None, 0) for mode 0, which is a constant fill of one word rather
    than a map, and raises when the mode is not an aligned entry of the table.
    Only the normal primary-plane reader masks bit 15; secondary callers must
    pass offset_variant=False instead of treating a signed offset as a flag.
    """
    if type(mode) is not int or not 0 <= mode <= 0xFFFF:
        raise ValueError("plane entry mode must be an unsigned word")
    if mode == CONSTANT_FILL_MODE:
        return None, 0
    flagged = bool(mode & OFFSET_VARIANT)
    table_offset = mode & ~OFFSET_VARIANT if offset_variant else mode
    index = (table_offset - MODE_BIAS) // 4
    if flagged and not offset_variant or table_offset % 4 != 0 or not 0 <= index < len(table):
        raise ValueError("plane entry mode $%X is not one of the %d in the table" % (mode, len(table)))
    offset = OFFSET_VARIANT_Y if flagged else 0
    return table[index], offset
