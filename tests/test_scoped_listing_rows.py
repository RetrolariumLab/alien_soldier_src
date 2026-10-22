"""Tiny fresh-byte listing-input controls; no ROM build or native execution."""

import os
from pathlib import Path
import re
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import derive_profile_name_addresses as listing
from authoring import guarded_inventory as inventory
from authoring import stage_tilemap_model as source


def row(address, field, text="dc.b 1"):
    return ("    1/%X : %s" % (address, field)).ljust(40) + text + "\n"


def legacy_bind(path, image):
    """The original streaming algorithm, independent of scoped input facts."""
    checked = 0
    with path.open(encoding="latin-1") as stream:
        for line_number, line in enumerate(stream, 1):
            found = listing.symbols.LISTING_ROW.match(line)
            if found is None or len(line) <= listing.symbols.SOURCE_COLUMN:
                continue
            field = line[line.index(":") + 1 : listing.symbols.SOURCE_COLUMN].strip()
            if not re.fullmatch(r"(?:[0-9A-Fa-f]{2,8}\s*)+", field):
                continue
            encoded, address = bytes.fromhex(field), int(found[1], 16)
            if address + len(encoded) > len(image) or image[address : address + len(encoded)] != encoded:
                raise ValueError(
                    "listing bytes differ from original ROM: %s:%d at $%06X" % (path, line_number, address)
                )
            checked += 1
    if not checked:
        raise ValueError("listing has no authenticated printed ROM byte fields: %s" % path)
    return checked


class ScopedListingRowsTests(unittest.TestCase):
    def setUp(self):
        parent = ROOT / "build/test-fixtures/scoped-listing-rows"
        parent.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix="owner-", dir=parent)
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.root = self.base / "root"
        (self.root / "src").mkdir(parents=True)
        (self.root / "data").mkdir()
        (self.root / "src/a.s").write_bytes(b"Byte: dc.b 1\n")
        (self.root / "data/a.bin").write_bytes(b"\1")
        self.path = self.write("build/main.lst", row(0, "0102").encode())
        self.image = b"\1\2\3\4"

    def write(self, relative, body):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(body)
        return path

    def test_legacy_parity_preserves_equ_abbreviations_short_rows_and_newlines(self):
        text = row(0, "0102") + row(0, "=$A10008", "IO equ $A10008")
        text += row(0, "0102 ...", 'binclude "blob.bin"') + "1/0: 01\n" + row(2, "0304")
        for newline in (b"\n", b"\r\n", b"\r"):
            with self.subTest(newline=newline):
                self.path.write_bytes(text.encode().replace(b"\n", newline))
                expected = legacy_bind(self.path, self.image)
                with source.parsed_operation(self.root) as operation:
                    self.assertEqual(expected, listing.bind_listing_bytes(self.path, self.image))
                    self.assertEqual(expected, listing.bind_listing_bytes(self.path, self.image))
                    self.assertEqual(2, expected)
                    self.assertEqual(1, len(operation._listing_row_cache))

    def test_latin1_vt_ff_nel_do_not_invent_extra_lines(self):
        for separator in (b"\v", b"\f", b"\x85"):
            with self.subTest(separator=separator):
                self.path.write_bytes(
                    row(0, "01").encode() + b"not-a-row" + separator + row(3, "FF").encode() + row(1, "02").encode()
                )
                self.assertEqual(2, legacy_bind(self.path, self.image))
                with source.parsed_operation(self.root):
                    self.assertEqual(2, listing.bind_listing_bytes(self.path, self.image))

    def test_no_printed_rows_keeps_exact_original_refusal(self):
        self.path.write_bytes(row(0, "=$1234", "Value equ $1234").encode())
        with self.assertRaises(ValueError) as original:
            legacy_bind(self.path, self.image)
        with source.parsed_operation(self.root):
            for _repeat in range(2):
                with self.assertRaises(ValueError) as actual:
                    listing.bind_listing_bytes(self.path, self.image)
                self.assertEqual(str(original.exception), str(actual.exception))

    def test_first_mismatch_and_short_rom_keep_exact_line_address_diagnostic(self):
        self.path.write_bytes(("header\n" + row(0, "01") + row(1, "02")).encode())
        for image in (b"\1\xff", b"\1"):
            with self.subTest(image=image):
                with self.assertRaises(ValueError) as original:
                    legacy_bind(self.path, image)
                with source.parsed_operation(self.root):
                    with self.assertRaises(ValueError) as actual:
                        listing.bind_listing_bytes(self.path, image)
                self.assertEqual(str(original.exception), str(actual.exception))
                self.assertIn(":3 at $000001", str(actual.exception))

    def test_identical_listing_does_not_cache_a_rom_comparison_or_pass_count(self):
        with source.parsed_operation(self.root) as operation:
            self.assertEqual(1, listing.bind_listing_bytes(self.path, self.image))
            with self.assertRaisesRegex(ValueError, "bytes differ"):
                listing.bind_listing_bytes(self.path, b"\xff\2\3\4")
            self.assertEqual(1, listing.bind_listing_bytes(self.path, self.image))
            self.assertEqual(1, len(operation._listing_row_cache))

    def test_eager_decode_failure_preserves_first_mismatch_bounds_and_bad_field_errors(self):
        for address, image in ((0, b"\xff"), (6, self.image), (0, self.image)):
            with self.subTest(address=address, image=image):
                self.path.write_bytes((row(address, "01") + row(1, "ABC")).encode())
                with self.assertRaises(ValueError) as original:
                    legacy_bind(self.path, image)
                with source.parsed_operation(self.root) as operation:
                    with self.assertRaises(ValueError) as actual:
                        listing.bind_listing_bytes(self.path, image)
                    self.assertEqual(str(original.exception), str(actual.exception))
                    self.assertFalse(operation._listing_row_cache)

    def test_non_plain_bytes_images_keep_genuine_streaming_parity(self):
        class Image:
            def __init__(self, body):
                self.body = body

            def __len__(self):
                return len(self.body)

            def __getitem__(self, key):
                return self.body[key]

        class BytesSubclass(bytes):
            pass

        for factory in (bytearray, Image, BytesSubclass):
            for body in (self.image, b"\xff\2\3\4"):
                with self.subTest(factory=factory, body=body):
                    image = factory(body)
                    with (
                        source.parsed_operation(self.root) as operation,
                        mock.patch.object(
                            operation, "listing_rows", side_effect=AssertionError("non-bytes cache admission")
                        ),
                    ):
                        if body == self.image:
                            self.assertEqual(
                                legacy_bind(self.path, image), listing.bind_listing_bytes(self.path, image)
                            )
                        else:
                            with self.assertRaises(ValueError) as original:
                                legacy_bind(self.path, image)
                            with self.assertRaises(ValueError) as actual:
                                listing.bind_listing_bytes(self.path, image)
                            self.assertEqual(str(original.exception), str(actual.exception))
                        self.assertFalse(operation._listing_row_cache)

    def test_each_cached_call_physically_reopens_current_listing_bytes(self):
        original_open = Path.open
        reads = []

        def counted(path, *args, **kwargs):
            if path == self.path:
                reads.append(args[0] if args else kwargs.get("mode", "r"))
            return original_open(path, *args, **kwargs)

        with source.parsed_operation(self.root), mock.patch.object(Path, "open", counted):
            listing.bind_listing_bytes(self.path, self.image)
            listing.bind_listing_bytes(self.path, self.image)
        self.assertEqual(["rb", "rb"], reads)

    def test_same_size_restored_mtime_rewrite_uses_fresh_hash_not_old_rows(self):
        with source.parsed_operation(self.root) as operation:
            listing.bind_listing_bytes(self.path, self.image)
            before = self.path.stat()
            self.path.write_bytes(row(0, "0103").encode())
            os.utime(self.path, ns=(before.st_atime_ns, before.st_mtime_ns))
            self.assertEqual(before.st_size, self.path.stat().st_size)
            self.assertEqual(before.st_mtime_ns, self.path.stat().st_mtime_ns)
            with self.assertRaisesRegex(ValueError, "bytes differ"):
                listing.bind_listing_bytes(self.path, self.image)
            self.assertEqual(1, listing.bind_listing_bytes(self.path, b"\1\3"))
            self.assertEqual(2, len(operation._listing_row_cache))

    def test_canonical_timestamp_rewrite_is_legal_without_old_filesystem_pin(self):
        with source.parsed_operation(self.root) as operation:
            for stamp in ("10/12/2026 23:26:8", "10/16/2026 11:12:3"):
                self.path.write_bytes((stamp + "\n" + row(0, "0102")).encode())
                self.assertEqual(1, listing.bind_listing_bytes(self.path, self.image))
            self.assertEqual(2, len(operation._listing_row_cache))

    def test_rows_are_only_immutable_builtin_data_with_independent_anchors(self):
        with source.parsed_operation(self.root) as operation:
            listing.bind_listing_bytes(self.path, self.image)
            key, rows = next(iter(operation._listing_row_cache.items()))
            self.assertIs(type(rows), tuple)
            self.assertTrue(all(type(item) is tuple and tuple(map(type, item)) == (int, int, bytes) for item in rows))
            self.assertIs(rows, operation._listing_row_anchors[0][1])
            self.assertEqual(key, operation._listing_row_anchors[0][0])
            with self.assertRaises(TypeError):
                rows[0][2][0] = 99

    def test_replacing_cached_rows_is_refused_and_poison_survives_restoration(self):
        with self.assertRaisesRegex(ValueError, "listing input cache is corrupt"):
            with source.parsed_operation(self.root) as operation:
                listing.bind_listing_bytes(self.path, self.image)
                key, original = next(iter(operation._listing_row_cache.items()))
                operation._listing_row_cache[key] = ((1, 0, b"\xff"),)
                with self.assertRaisesRegex(ValueError, "listing input cache is corrupt"):
                    listing.bind_listing_bytes(self.path, b"\xff")
                operation._listing_row_cache[key] = original
                with self.assertRaisesRegex(ValueError, "listing input cache is corrupt"):
                    operation.listing_rows(self.path, self.path.read_bytes(), listing._listing_parser_policy())
        self.assertIsNone(source._PARSED_OPERATION.get())

    def test_last_callback_cache_tampering_is_caught_by_final_close(self):
        for change in (
            lambda operation: operation._listing_row_cache.clear(),
            lambda operation: setattr(operation, "_listing_row_cache", []),
            lambda operation: setattr(operation, "_listing_row_anchors", []),
        ):
            with self.subTest(change=change):
                with self.assertRaisesRegex(ValueError, "listing input cache is corrupt"):
                    with source.parsed_operation(self.root) as operation:
                        listing.bind_listing_bytes(self.path, self.image)
                        change(operation)

    def test_tampering_from_last_original_raw_closer_cannot_escape_final_guard(self):
        actual_close, closed = inventory.close, []

        def close_then_tamper(owner, frozen, **kwargs):
            actual_close(owner, frozen, **kwargs)
            closed.append(owner)
            if owner == self.root / "data":
                operation._listing_row_cache.clear()

        with mock.patch.object(inventory, "close", close_then_tamper):
            with self.assertRaisesRegex(ValueError, "listing input cache is corrupt"):
                with source.parsed_operation(self.root) as operation:
                    source.labelled_blocks(self.root)
                    listing.bind_listing_bytes(self.path, self.image)
        self.assertEqual([self.root / "src", self.root / "data"], closed)

    def test_body_cache_corruption_cannot_skip_original_source_physical_closers(self):
        actual_close, closed = inventory.close, []

        def observed_close(owner, frozen, **kwargs):
            actual_close(owner, frozen, **kwargs)
            closed.append(owner)

        with mock.patch.object(inventory, "close", observed_close):
            with self.assertRaisesRegex(ValueError, "listing input cache is corrupt"):
                with source.parsed_operation(self.root) as operation:
                    source.labelled_blocks(self.root)
                    listing.bind_listing_bytes(self.path, self.image)
                    operation._listing_row_cache.clear()
        self.assertEqual([self.root / "src", self.root / "data"], closed)
        self.assertTrue(operation._listing_corrupt)
        self.assertIsNone(source._PARSED_OPERATION.get())

    def test_existing_readonly_owner_physical_closer_still_rejects_late_bytes(self):
        private = self.path.parent
        frozen = inventory.capture(private, max_file=1024, max_total=4096, max_entries=16)
        with self.assertRaisesRegex(ValueError, "raw file changed"):
            with source.parsed_operation(self.root):
                listing.bind_listing_bytes(self.path, self.image)
                self.path.write_bytes(row(0, "0103").encode())
                inventory.close(private, frozen, max_file=1024, max_entries=16)

    def test_no_scope_foreign_root_and_noncanonical_path_keep_streaming_fallback(self):
        self.assertEqual(1, listing.bind_listing_bytes(self.path, self.image))
        foreign = self.base / "foreign.lst"
        foreign.write_bytes(row(0, "0102").encode())
        alias = self.root / "build/../build/main.lst"
        with source.parsed_operation(self.root) as operation:
            self.assertEqual(1, listing.bind_listing_bytes(foreign, self.image))
            self.assertEqual(1, listing.bind_listing_bytes(alias, self.image))
            self.assertIsNone(operation.listing_rows(foreign, foreign.read_bytes(), listing._listing_parser_policy()))
            self.assertFalse(operation._listing_row_cache)

    def test_closed_or_foreign_pid_capability_refuses_but_standalone_is_fresh(self):
        with source.parsed_operation(self.root) as operation:
            listing.bind_listing_bytes(self.path, self.image)
            with mock.patch.object(source.os, "getpid", return_value=operation.pid + 1):
                with self.assertRaisesRegex(ValueError, "closed or outside"):
                    operation.listing_rows(self.path, self.path.read_bytes(), listing._listing_parser_policy())
        with self.assertRaisesRegex(ValueError, "closed or outside"):
            operation.listing_rows(self.path, self.path.read_bytes(), listing._listing_parser_policy())
        self.path.write_bytes(row(0, "0103").encode())
        self.assertEqual(1, listing.bind_listing_bytes(self.path, b"\1\3"))

    def test_file_key_body_and_row_capacity_limits_keep_genuine_legacy_fallback(self):
        for name in ("_LISTING_MAX_FILE", "_LISTING_MAX_KEYS", "_LISTING_MAX_TOTAL", "_LISTING_MAX_ROWS"):
            with self.subTest(limit=name), mock.patch.object(source, name, 0):
                with source.parsed_operation(self.root) as operation:
                    self.assertEqual(
                        legacy_bind(self.path, self.image), listing.bind_listing_bytes(self.path, self.image)
                    )
                    self.assertFalse(operation._listing_row_cache)

    def test_cumulative_capacity_does_not_evict_or_replace_original_entries(self):
        other = self.write("build/other.lst", row(2, "0304").encode())
        with mock.patch.object(source, "_LISTING_MAX_KEYS", 1):
            with source.parsed_operation(self.root) as operation:
                listing.bind_listing_bytes(self.path, self.image)
                original = operation._listing_row_anchors
                self.assertEqual(1, listing.bind_listing_bytes(other, self.image))
                self.assertIs(original, operation._listing_row_anchors)
                self.assertEqual(1, len(operation._listing_row_cache))

    def test_changed_grammar_or_parser_code_keeps_original_streaming_semantics(self):
        for name, value in (("SOURCE_COLUMN", 39), ("LISTING_ROW", re.compile(r"^NOT_A_ROW$"))):
            with self.subTest(policy=name), source.parsed_operation(self.root) as operation:
                listing.bind_listing_bytes(self.path, self.image)
                with (
                    mock.patch.object(listing.symbols, name, value),
                    mock.patch.object(
                        operation, "listing_rows", side_effect=AssertionError("unsupported policy reused cache")
                    ),
                ):
                    if name == "LISTING_ROW":
                        with self.assertRaisesRegex(ValueError, "no authenticated printed"):
                            listing.bind_listing_bytes(self.path, self.image)
                    else:
                        self.assertEqual(
                            legacy_bind(self.path, self.image), listing.bind_listing_bytes(self.path, self.image)
                        )
                self.assertEqual(1, len(operation._listing_row_cache))
        with (
            source.parsed_operation(self.root) as operation,
            mock.patch.object(
                listing, "_parse_listing_rows", side_effect=AssertionError("unsupported parser executed")
            ),
        ):
            self.assertEqual(1, listing.bind_listing_bytes(self.path, self.image))
            self.assertFalse(operation._listing_row_cache)


if __name__ == "__main__":
    unittest.main()
