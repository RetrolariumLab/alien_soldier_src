"""Operation-local, no-follow file inventories and original-byte closure.

Every file is reopened and hashed. Only traversal of already guarded parents
is shared: no qualification verdict or inventory survives an operation here.
"""

from __future__ import annotations

from collections import deque
from concurrent.futures import ThreadPoolExecutor
import hashlib
import os
import re
import stat

# Cartridge/source owners contain many small files. On the measured Windows
# workload, inline reads avoid pool startup and per-file Future/context-switch
# overhead. Positive widths retain the bounded asynchronous implementation.
READ_WORKERS = 0
MAX_PENDING = 16


class _Reads:
    """Inline physical reads by default; optional bounded reader queue."""

    def __init__(self, collect):
        self.collect, self.pending, self.executor = collect, deque(), None
        self.synchronous = False

    def __enter__(self):
        self.synchronous = READ_WORKERS == 0
        if not self.synchronous:
            self.executor = ThreadPoolExecutor(max_workers=READ_WORKERS, thread_name_prefix="guarded-inventory-read")
        return self

    def __exit__(self, _kind, _value, _traceback):
        # Discovery, reading, collection and final guards can all fail. Never
        # return to the caller while any owned reader is still running.
        try:
            if self.executor is not None:
                self.executor.shutdown(wait=True, cancel_futures=True)
        finally:
            self.synchronous = False

    def submit(self, path, owner, info, max_file, relative):
        if self.synchronous:
            self.collect(relative, _file_record(path, owner, info, max_file))
            return
        self.pending.append((relative, self.executor.submit(_file_record, path, owner, info, max_file)))
        if len(self.pending) >= MAX_PENDING:
            self._collect_one()

    def _collect_one(self):
        relative, future = self.pending.popleft()
        self.collect(relative, future.result())

    def drain(self):
        while self.pending:
            self._collect_one()


def _identity(info):
    # Windows path-stat/fstat may present permissions/ctime differently.
    # Compare full mode/ctime only within the SAME API below.
    # Directory storage size may change on enumeration without an entry change.
    # Keep directory identity, timestamps and names; pin regular-file size too.
    size = None if stat.S_ISDIR(info.st_mode) else info.st_size
    return (
        info.st_dev,
        info.st_ino,
        stat.S_IFMT(info.st_mode),
        info.st_nlink,
        size,
        info.st_mtime_ns,
        getattr(info, "st_birthtime_ns", None),
        getattr(info, "st_file_attributes", 0),
    )


def _same_identity(before, after):
    return (
        _identity(before) == _identity(after)
        and before.st_mode == after.st_mode
        and before.st_ctime_ns == after.st_ctime_ns
    )


def _checked_stat(path):
    info = path.stat(follow_symlinks=False)
    if stat.S_ISLNK(info.st_mode) or getattr(info, "st_file_attributes", 0) & getattr(
        stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400
    ):
        raise ValueError("source/owner path crosses a link/reparse point")
    return info


def _owner(owner):
    owner = owner.absolute()
    if ".." in owner.parts:
        raise ValueError("source/owner path escapes its exact trusted owner")
    ancestors = []
    for path in reversed((owner, *owner.parents)):
        try:
            info = _checked_stat(path)
        except (FileNotFoundError, NotADirectoryError) as error:
            raise ValueError("source owner directory is missing") from error
        if not stat.S_ISDIR(info.st_mode):
            raise ValueError("source owner directory is missing")
        ancestors.append((path, info))
    return owner, ancestors


def _close_ancestors(ancestors):
    for index, (path, original) in enumerate(ancestors):
        current = _checked_stat(path)

        def stable(info):
            return (info.st_dev, info.st_ino, stat.S_IFMT(info.st_mode), getattr(info, "st_birthtime_ns", None))

        # Sibling files outside the exact owner may legitimately change parent
        # mtime/ctime/size/nlink. Only pin ancestry identity there, not contents.
        matches = (
            _same_identity(original, current) if index == len(ancestors) - 1 else stable(original) == stable(current)
        )
        if not stat.S_ISDIR(current.st_mode) or not matches:
            raise ValueError("source/owner ancestor directory changed during its inventory")


def _names(directory, max_entries):
    names, aliases = [], set()
    with os.scandir(directory) as entries:
        for entry in entries:
            name = entry.name
            if (
                name in {"", ".", ".."}
                or any(char in name for char in ("/", "\\", ":"))
                or any(ord(char) < 32 or ord(char) == 127 for char in name)
                or name.casefold() in aliases
            ):
                raise ValueError("source/owner entry has an alias spelling")
            if len(names) >= max_entries:
                raise ValueError("source owner exceeds its entry bound")
            aliases.add(name.casefold())
            names.append(name)
    return sorted(names)


def _file_bounds(info, max_file):
    if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
        raise ValueError("source/owner file is missing, nonregular or hard-linked")
    if type(info.st_size) is not int or not 0 <= info.st_size <= max_file:
        raise ValueError("source/owner file exceeds its typed byte bound")


def _file_record(path, owner, info, max_file):
    """Hash a child of an already guarded parent, retaining path/handle identity."""
    _file_bounds(info, max_file)
    digest, count = hashlib.sha256(), 0
    with path.open("rb") as stream:
        opened = os.fstat(stream.fileno())
        if _identity(opened) != _identity(info):
            raise ValueError("source/owner file identity changed before its read")
        while True:
            block = stream.read(min(65536, max_file - count + 1))
            if not block:
                break
            count += len(block)
            if count > max_file:
                raise ValueError("source/owner file grew beyond its typed byte bound")
            digest.update(block)
        if not _same_identity(opened, os.fstat(stream.fileno())):
            raise ValueError("source/owner raw file changed while being read")
    after = _checked_stat(path)
    if count != info.st_size or not _same_identity(info, after):
        raise ValueError("source/owner raw file changed while being read")
    return {"path": path.relative_to(owner).as_posix(), "bytes": count, "sha256": digest.hexdigest()}


def _validate_record(record, relative, max_file, context):
    if (
        type(record) is not dict
        or set(record) != {"path", "bytes", "sha256"}
        or type(record["path"]) is not str
        or record["path"] != relative
        or type(record["bytes"]) is not int
        or not 0 <= record["bytes"] <= max_file
        or type(record["sha256"]) is not str
        or not re.fullmatch(r"[0-9a-f]{64}", record["sha256"])
    ):
        raise ValueError(context + " file exceeds its typed byte bound")


def capture(
    owner,
    *,
    max_file,
    max_total,
    max_entries,
    validate_entry=None,
    context="source owner",
    total_bound="total byte bound",
):
    """Capture every regular file and directory in one bounded physical owner."""
    if any(type(value) is not int or value < 0 for value in (max_file, max_total, max_entries)):
        raise ValueError("source/owner limits require typed nonnegative integers")
    owner, ancestors = _owner(owner)
    result, total, reserved = {}, 0, 0

    def collect(relative, record):
        nonlocal total
        _validate_record(record, relative, max_file, context)
        total += record["bytes"]
        if total > max_total:
            raise ValueError(context + " exceeds its " + total_bound)
        result[relative] = {"kind": "file", "bytes": record["bytes"], "sha256": record["sha256"]}

    def walk(directory, relative, before):
        nonlocal reserved
        names = _names(directory, max_entries)
        for name in names:
            child = name if not relative else relative + "/" + name
            path = directory / name
            info = _checked_stat(path)
            is_directory = stat.S_ISDIR(info.st_mode)
            if validate_entry is not None:
                validate_entry(child, is_directory)
            if len(result) >= max_entries:
                raise ValueError(context + " exceeds its entry bound")
            if is_directory:
                result[child] = {"kind": "directory"}
                walk(path, child, info)
            else:
                _file_bounds(info, max_file)
                reserved += info.st_size
                if reserved > max_total:
                    raise ValueError(context + " exceeds its " + total_bound)
                # Preserve deterministic traversal order and count pending
                # entries before workers complete their genuine raw reads.
                result[child] = None
                reads.submit(path, owner, info, max_file, child)
        reads.drain()
        after_names, after = _names(directory, max_entries), _checked_stat(directory)
        if names != after_names or not _same_identity(before, after):
            raise ValueError(
                "source/owner immediate directory inventory changed during its scan: %s; "
                "identity=%r -> %r; ctime=%r -> %r; names_changed=%r"
                % (
                    relative or ".",
                    _identity(before),
                    _identity(after),
                    before.st_ctime_ns,
                    after.st_ctime_ns,
                    names != after_names,
                )
            )

    with _Reads(collect) as reads:
        walk(owner, "", ancestors[-1][1])
        _close_ancestors(ancestors)
    return result


def _frozen_children(frozen, max_file, max_entries):
    if type(frozen) is not dict or len(frozen) > max_entries:
        raise ValueError("frozen source/owner exceeds its typed entry bound")
    children, spellings = {"": set()}, set()
    for relative, row in frozen.items():
        if (
            type(relative) is not str
            or not relative
            or "\\" in relative
            or ":" in relative
            or any(part in {"", ".", ".."} for part in relative.split("/"))
            or any(ord(char) < 32 or ord(char) == 127 for char in relative)
            or type(row) is not dict
        ):
            raise ValueError("frozen source/owner path has an alias spelling")
        if relative.casefold() in spellings:
            raise ValueError("frozen source/owner path has an alias spelling")
        spellings.add(relative.casefold())
        parent, _, name = relative.rpartition("/")
        children.setdefault(parent, set()).add(name)
        if type(row.get("kind")) is str and row == {"kind": "directory"}:
            children.setdefault(relative, set())
        elif (
            set(row) != {"kind", "bytes", "sha256"}
            or type(row["kind"]) is not str
            or row["kind"] != "file"
            or type(row["bytes"]) is not int
            or not 0 <= row["bytes"] <= max_file
            or type(row["sha256"]) is not str
            or not re.fullmatch(r"[0-9a-f]{64}", row["sha256"])
        ):
            raise ValueError("frozen source/owner raw record has malformed typed bounds")
    for parent in children:
        if parent and frozen.get(parent) != {"kind": "directory"}:
            raise ValueError("frozen source/owner parent directory is missing")
    return children


def close_layout(owner, frozen, *, max_file, max_entries):
    """Close ORIGINAL names/types/bounds only; never read bytes or derive hashes."""
    if any(type(value) is not int or value < 0 for value in (max_file, max_entries)):
        raise ValueError("source/owner limits require typed nonnegative integers")
    children = _frozen_children(frozen, max_file, max_entries)
    owner, ancestors = _owner(owner)

    def walk(directory, relative, before):
        names = _names(directory, max_entries)
        if set(names) != children[relative]:
            raise ValueError("frozen source/owner immediate directory inventory changed")
        for name in names:
            child = name if not relative else relative + "/" + name
            path, original = directory / name, frozen[child]
            info = _checked_stat(path)
            if original["kind"] == "directory":
                if not stat.S_ISDIR(info.st_mode):
                    raise ValueError("frozen source/owner immediate directory inventory changed")
                walk(path, child, info)
            else:
                _file_bounds(info, max_file)
        if names != _names(directory, max_entries) or not _same_identity(before, _checked_stat(directory)):
            raise ValueError("frozen source/owner immediate directory inventory changed during its scan")

    walk(owner, "", ancestors[-1][1])
    _close_ancestors(ancestors)


def close(owner, frozen, *, max_file, max_entries):
    """Reopen ONLY original files; never adopt new names or a replacement hash.

    Aggregate capacity was checked when the original census was captured.
    Exact original bytes here also close owners whose approved bound is 1GiB,
    without accidentally imposing the single-format capture's 512MiB policy.
    """
    if any(type(value) is not int or value < 0 for value in (max_file, max_entries)):
        raise ValueError("source/owner limits require typed nonnegative integers")
    children = _frozen_children(frozen, max_file, max_entries)
    owner, ancestors = _owner(owner)

    def collect(relative, record):
        _validate_record(record, relative, max_file, "frozen source/owner")
        current = {"kind": "file", "bytes": record["bytes"], "sha256": record["sha256"]}
        if current != frozen[relative]:
            raise ValueError("frozen source/owner raw file changed")

    def walk(directory, relative, before):
        names = _names(directory, max_entries)
        if set(names) != children[relative]:
            raise ValueError("frozen source/owner immediate directory inventory changed")
        for name in names:
            child = name if not relative else relative + "/" + name
            path, original = directory / name, frozen[child]
            info = _checked_stat(path)
            if original["kind"] == "directory":
                if not stat.S_ISDIR(info.st_mode):
                    raise ValueError("frozen source/owner immediate directory inventory changed")
                walk(path, child, info)
            else:
                _file_bounds(info, max_file)
                reads.submit(path, owner, info, max_file, child)
        reads.drain()
        if names != _names(directory, max_entries) or not _same_identity(before, _checked_stat(directory)):
            raise ValueError("frozen source/owner immediate directory inventory changed during its scan")

    with _Reads(collect) as reads:
        walk(owner, "", ancestors[-1][1])
        _close_ancestors(ancestors)
