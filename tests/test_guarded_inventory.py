"""Physical bounded-walk controls; no assembler, emulator or cached verdict."""

from copy import deepcopy
from concurrent.futures import ThreadPoolExecutor
import hashlib
import os
from pathlib import Path
import stat
import sys
import tempfile
import threading
from types import SimpleNamespace
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import guarded_inventory as inventory


class GuardedInventoryTests(unittest.TestCase):
    def setUp(self):
        base = ROOT / "build/test-fixtures/guarded-inventory"
        base.mkdir(parents=True, exist_ok=True)
        owner = tempfile.TemporaryDirectory(prefix="owner-", dir=base)
        self.addCleanup(owner.cleanup)
        self.owner = Path(owner.name)

    def write(self, relative, body=b"source bytes"):
        path = self.owner / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(body)
        return path

    def capture(self, **kwargs):
        return inventory.capture(self.owner, **({"max_file": 1024, "max_total": 4096,
            "max_entries": 32} | kwargs))

    def close(self, original):
        inventory.close(self.owner, original, max_file=1024, max_entries=32)

    @staticmethod
    def info(original, **changes):
        values = {name: getattr(original, name) for name in (
            "st_dev", "st_ino", "st_mode", "st_nlink", "st_size", "st_mtime_ns", "st_ctime_ns")}
        for name in ("st_birthtime_ns", "st_file_attributes"):
            if hasattr(original, name):
                values[name] = getattr(original, name)
        return SimpleNamespace(**dict(values, **changes))

    def test_actual_sha_and_empty_directories_are_captured_and_closed(self):
        self.write("nested/input.bin", b"actual bytes")
        (self.owner / "empty").mkdir()
        original = self.capture()
        self.assertEqual({"empty", "nested", "nested/input.bin"}, set(original))
        self.assertEqual({"kind": "directory"}, original["empty"])
        self.assertEqual({"kind": "file", "bytes": 12,
            "sha256": hashlib.sha256(b"actual bytes").hexdigest()}, original["nested/input.bin"])
        self.close(original)

    def test_directory_storage_size_may_change_without_changing_entries(self):
        path = self.write("nested/input.bin", b"unchanged physical input")
        actual, calls = Path.stat, []

        def directory_size(candidate, *, follow_symlinks=True):
            info = actual(candidate, follow_symlinks=follow_symlinks)
            if candidate == path.parent:
                calls.append(True)
                return self.info(info, st_size=4096 if len(calls) % 2 else 0)
            return info

        with mock.patch.object(Path, "stat", side_effect=directory_size, autospec=True):
            original = self.capture()
            self.close(original)
        self.assertGreaterEqual(len(calls), 4)
        self.assertEqual(hashlib.sha256(b"unchanged physical input").hexdigest(),
                         original["nested/input.bin"]["sha256"])

    def test_regular_file_size_remains_part_of_handle_identity(self):
        path = self.write("one.bin", b"physical source bytes")
        inode, actual = path.stat().st_ino, os.fstat

        def changed_size(descriptor):
            info = actual(descriptor)
            return self.info(info, st_size=info.st_size + 1) if info.st_ino == inode else info

        with mock.patch.object(inventory.os, "fstat", side_effect=changed_size):
            with self.assertRaisesRegex(ValueError, "identity changed"):
                self.capture()

    def test_empty_owner_still_has_a_real_guarded_root(self):
        self.assertEqual({}, self.capture())
        self.close({})
        (self.owner / "late-empty").mkdir()
        with self.assertRaisesRegex(ValueError, "immediate directory"):
            self.close({})

    def test_file_total_entry_and_typed_limit_bounds_remain_separate(self):
        self.write("one.bin", b"1234")
        self.write("two.bin", b"5678")
        for kwargs, message in (({"max_file": 3}, "typed byte bound"),
                                ({"max_total": 7}, "total byte bound"),
                                ({"max_entries": 1}, "entry bound"),
                                ({"max_file": True}, "typed nonnegative")):
            with self.subTest(kwargs=kwargs), self.assertRaisesRegex(ValueError, message):
                self.capture(**kwargs)

    def test_returned_file_record_shape_digest_path_and_typed_bytes_are_checked(self):
        self.write("one.bin", b"1234")
        actual = inventory._file_record
        for changes in ({"bytes": True}, {"bytes": 1.0}, {"bytes": 1025},
                        {"sha256": "invalid"}, {"path": "elsewhere"}, {"unexpected": False}):
            def changed(*args):
                return dict(actual(*args), **changes)
            with self.subTest(changes=changes), mock.patch.object(inventory, "_file_record", side_effect=changed):
                with self.assertRaisesRegex(ValueError, "typed byte bound"):
                    self.capture()

    def test_close_rejects_original_raw_rewrite_and_does_not_adopt_new_hash(self):
        path = self.write("one.bin", b"1234")
        original = self.capture()
        before = deepcopy(original)
        path.write_bytes(b"5678")
        with self.assertRaisesRegex(ValueError, "raw file changed"):
            self.close(original)
        self.assertEqual(before, original)

    def test_added_removed_file_and_empty_directory_are_never_adopted(self):
        path = self.write("one.bin")
        (self.owner / "empty").mkdir()
        original = self.capture()
        extra = self.write("empty/extra.bin")
        with self.assertRaisesRegex(ValueError, "immediate directory"):
            self.close(original)
        extra.unlink()
        path.unlink()
        with self.assertRaisesRegex(ValueError, "immediate directory"):
            self.close(original)

    def test_real_hardlink_is_refused_without_mutating_either_file(self):
        path = self.write("one.bin")
        alias = self.owner / "alias.bin"
        os.link(path, alias)
        with self.assertRaisesRegex(ValueError, "hard-linked"):
            self.capture()
        self.assertEqual(b"source bytes", path.read_bytes())
        self.assertEqual(path.read_bytes(), alias.read_bytes())

    def test_symlink_and_junction_nofollow_stats_fail_closed(self):
        path = self.write("one.bin")
        actual = Path.stat
        for junction in (False, True):
            def linked(candidate, *, follow_symlinks=True):
                info = actual(candidate, follow_symlinks=follow_symlinks)
                if candidate == path and not follow_symlinks:
                    return self.info(info, st_mode=info.st_mode if junction else stat.S_IFLNK,
                        st_file_attributes=getattr(info, "st_file_attributes", 0) | (0x400 if junction else 0))
                return info
            with self.subTest(junction=junction), mock.patch.object(Path, "stat", side_effect=linked, autospec=True):
                with self.assertRaisesRegex(ValueError, "link/reparse"):
                    self.capture()

    def test_scandir_permission_failure_never_returns_a_partial_census(self):
        path = self.write("nested/one.bin")
        actual = inventory.os.scandir
        def denied(directory):
            if directory == path.parent:
                raise PermissionError("actual descendant unreadable")
            return actual(directory)
        with mock.patch.object(inventory.os, "scandir", side_effect=denied):
            with self.assertRaisesRegex(PermissionError, "unreadable"):
                self.capture()

    def test_file_handle_identity_and_same_api_ctime_are_not_interchangeable(self):
        path = self.write("one.bin")
        inode, actual = path.stat().st_ino, inventory.os.fstat
        for field in ("st_ino", "st_ctime_ns"):
            calls = []
            def changed(descriptor):
                info = actual(descriptor)
                if info.st_ino == inode:
                    calls.append(True)
                    if field == "st_ino" or len(calls) == 2:
                        return self.info(info, **{field: getattr(info, field) + 1})
                return info
            with self.subTest(field=field), mock.patch.object(inventory.os, "fstat", side_effect=changed):
                with self.assertRaisesRegex(ValueError, "identity changed|raw file changed"):
                    self.capture()

    def test_actual_exe_name_keeps_genuine_path_handle_capture_and_close(self):
        body = b"nonexecuted EXE-named fixture"
        path = self.write("native/helper.exe", body)
        with path.open("rb") as stream:
            self.assertTrue(stat.S_ISREG(os.fstat(stream.fileno()).st_mode))
            self.assertEqual(stat.S_IFMT(path.stat().st_mode),
                             stat.S_IFMT(os.fstat(stream.fileno()).st_mode))
        original = self.capture()
        self.assertEqual({"kind": "file", "bytes": len(body),
            "sha256": hashlib.sha256(body).hexdigest()}, original["native/helper.exe"])
        self.close(original)

    def test_stable_cross_api_permissions_and_ctime_keep_actual_bytes(self):
        path = self.write("one.bin", b"physical source bytes")
        actual, calls = inventory.os.fstat, []
        def presentation(descriptor):
            info = actual(descriptor)
            calls.append(True)
            return self.info(info, st_mode=info.st_mode ^ 0o100,
                             st_ctime_ns=info.st_ctime_ns + 12345)
        with mock.patch.object(inventory.os, "fstat", side_effect=presentation):
            original = self.capture()
            self.close(original)
        self.assertEqual(4, len(calls))
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), original["one.bin"]["sha256"])

    def test_same_api_path_and_handle_permission_bit_changes_still_refuse(self):
        path = self.write("one.bin")
        for api in ("path", "handle"):
            calls = []
            actual = inventory._checked_stat if api == "path" else inventory.os.fstat
            def changed(value):
                info = actual(value)
                if api == "handle" or value == path:
                    calls.append(True)
                    if len(calls) == 2:
                        return self.info(info, st_mode=info.st_mode ^ 0o100)
                return info
            target, name = (inventory, "_checked_stat") if api == "path" else (inventory.os, "fstat")
            with self.subTest(api=api), mock.patch.object(target, name, side_effect=changed):
                with self.assertRaisesRegex(ValueError, "raw file changed"):
                    self.capture()
            self.assertEqual(2, len(calls))

    def test_cross_and_same_api_file_type_changes_still_refuse(self):
        path = self.write("one.bin")
        for api in ("cross", "path", "handle"):
            calls = []
            actual = inventory._checked_stat if api == "path" else inventory.os.fstat
            def changed(value):
                info = actual(value)
                if api != "path" or value == path:
                    calls.append(True)
                    if len(calls) == (1 if api == "cross" else 2):
                        return self.info(info, st_mode=stat.S_IFDIR | stat.S_IMODE(info.st_mode))
                return info
            target, name = (inventory, "_checked_stat") if api == "path" else (inventory.os, "fstat")
            with self.subTest(api=api), mock.patch.object(target, name, side_effect=changed):
                with self.assertRaisesRegex(ValueError, "identity changed|raw file changed"):
                    self.capture()
            self.assertEqual(1 if api == "cross" else 2, len(calls))

    def test_stable_fstat_ctime_may_differ_from_stable_path_ctime(self):
        self.write("one.bin")
        actual, calls = inventory.os.fstat, []
        def handle_clock(descriptor):
            info = actual(descriptor)
            calls.append(True)
            # Only API-specific clock presentation is synthetic: real file
            # identities, owned paths, stream reads and SHA remain unchanged.
            return self.info(info, st_ctime_ns=info.st_ctime_ns + 12345)
        with mock.patch.object(inventory.os, "fstat", side_effect=handle_clock):
            original = self.capture()
            self.close(original)
        self.assertEqual(4, len(calls))

    def test_actual_growth_during_stream_read_is_refused(self):
        path = self.write("one.bin", b"1")
        actual = inventory.os.fstat
        inode, changed = path.stat().st_ino, []
        def grow(descriptor):
            info = actual(descriptor)
            if info.st_ino == inode and not changed:
                changed.append(True)
                path.write_bytes(b"12345")
            return info
        with mock.patch.object(inventory.os, "fstat", side_effect=grow):
            with self.assertRaisesRegex(ValueError, "grew beyond"):
                self.capture(max_file=4)
        self.assertEqual([True], changed)

    def test_final_nofollow_path_identity_is_checked_after_handle_close(self):
        path = self.write("one.bin")
        actual, reads = inventory._checked_stat, []
        def replaced(candidate):
            info = actual(candidate)
            if candidate == path:
                reads.append(True)
                if len(reads) == 2:
                    return self.info(info, st_ino=info.st_ino + 1)
            return info
        with mock.patch.object(inventory, "_checked_stat", side_effect=replaced):
            with self.assertRaisesRegex(ValueError, "raw file changed"):
                self.capture()
        self.assertEqual(2, len(reads))

    def test_changed_directory_identity_and_names_are_checked_after_descent(self):
        path = self.write("nested/one.bin")
        actual = inventory._file_record
        def late(*args):
            result = actual(*args)
            (path.parent / "late-empty").mkdir()
            return result
        with mock.patch.object(inventory, "_file_record", side_effect=late):
            with self.assertRaisesRegex(ValueError, "immediate directory"):
                self.capture()

    def test_external_ancestor_sibling_metadata_is_not_an_owner_content_guard(self):
        self.write("one.bin")
        actual, calls = inventory._checked_stat, []
        ancestor = self.owner.parent
        def external(candidate):
            info = actual(candidate)
            if candidate == ancestor:
                calls.append(True)
                if len(calls) == 2:
                    return self.info(info, st_mtime_ns=info.st_mtime_ns + 1,
                        st_ctime_ns=info.st_ctime_ns + 1, st_size=info.st_size + 1, st_nlink=info.st_nlink + 1)
            return info
        with mock.patch.object(inventory, "_checked_stat", side_effect=external):
            original = self.capture()
        self.assertEqual(2, len(calls))
        self.close(original)

    def test_external_ancestor_replacement_still_refuses(self):
        self.write("one.bin")
        actual, calls = inventory._checked_stat, []
        ancestor = self.owner.parent
        def external(candidate):
            info = actual(candidate)
            if candidate == ancestor:
                calls.append(True)
                if len(calls) == 2:
                    return self.info(info, st_ino=info.st_ino + 1)
            return info
        with mock.patch.object(inventory, "_checked_stat", side_effect=external):
            with self.assertRaisesRegex(ValueError, "ancestor directory changed"):
                self.capture()

    def test_frozen_census_types_canonical_names_parents_and_bounds_are_checked(self):
        path = self.write("nested/one.bin")
        original = self.capture()
        for bad in ([], {"../outside": {"kind": "directory"}}, {"nested/../one.bin": {"kind": "directory"}},
                    {"nested/one.bin": original["nested/one.bin"]},
                    {"nested": {"kind": "file", "bytes": True, "sha256": "0" * 64}},
                    {"nested": {"kind": "directory"}, "NESTED": {"kind": "directory"}},
                    {"nested": {"kind": "directory", "extra": False}}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                self.close(bad)
        self.assertEqual(b"source bytes", path.read_bytes())

    def test_top_level_policy_refuses_foreign_directory_before_descent(self):
        (self.owner / "foreign").mkdir()
        calls = []
        def policy(relative, is_directory):
            calls.append((relative, is_directory))
            raise ValueError("foreign owner")
        with self.assertRaisesRegex(ValueError, "foreign owner"):
            self.capture(validate_entry=policy)
        self.assertEqual([("foreign", True)], calls)

    def test_parallel_readers_and_global_pending_queue_are_bounded_and_ordered(self):
        names = ["%02d.bin" % index for index in range(40)]
        for name in names:
            self.write(name)
        actual, lock, gate = inventory._file_record, threading.Lock(), threading.Event()
        main_thread = threading.get_ident()
        metrics = {"active": 0, "peak_active": 0, "pending": 0, "peak_pending": 0,
                   "executors": 0, "readers": 0, "worker_limit": None}
        collected, callbacks = [], []

        class Result:
            def __init__(self, future, name):
                self.future, self.name = future, name

            def result(self):
                try:
                    return self.future.result()
                finally:
                    with lock:
                        metrics["pending"] -= 1
                        collected.append(self.name)

        class TrackedExecutor(ThreadPoolExecutor):
            def __init__(self, *, max_workers, thread_name_prefix):
                metrics["executors"] += 1
                metrics["worker_limit"] = max_workers
                super().__init__(max_workers=max_workers, thread_name_prefix=thread_name_prefix)

            def submit(self, function, path, *args):
                with lock:
                    metrics["pending"] += 1
                    metrics["peak_pending"] = max(metrics["peak_pending"], metrics["pending"])
                    if metrics["pending"] > 16:
                        raise AssertionError("global pending queue exceeded16")
                return Result(super().submit(function, path, *args), path.name)

        def reader(*args):
            self.assertNotEqual(main_thread, threading.get_ident())
            with lock:
                metrics["active"] += 1
                metrics["readers"] += 1
                metrics["peak_active"] = max(metrics["peak_active"], metrics["active"])
                if metrics["active"] == inventory.READ_WORKERS:
                    gate.set()
            try:
                if not gate.wait(2):
                    raise AssertionError("bounded workers did not overlap")
                return actual(*args)
            finally:
                with lock:
                    metrics["active"] -= 1

        def policy(relative, is_directory):
            self.assertEqual(main_thread, threading.get_ident())
            callbacks.append((relative, is_directory))

        with mock.patch.object(inventory, "READ_WORKERS", 8), \
                mock.patch.object(inventory, "ThreadPoolExecutor", TrackedExecutor), \
                mock.patch.object(inventory, "_file_record", side_effect=reader):
            original = self.capture(max_entries=64, validate_entry=policy)
            inventory.close(self.owner, original, max_file=1024, max_entries=64)
        self.assertEqual(2, metrics["executors"])
        self.assertEqual(8, metrics["worker_limit"])
        self.assertEqual(8, metrics["peak_active"])
        self.assertEqual(16, metrics["peak_pending"])
        self.assertEqual((0, 0, 80), (metrics["active"], metrics["pending"], metrics["readers"]))
        self.assertEqual(names + names, collected)
        self.assertEqual(names, list(original))
        self.assertEqual([(name, False) for name in names], callbacks)
        # The production inline path performs the same 80 genuine reads and
        # ordered collections without constructing any executor or Future.
        self.assertEqual(0, inventory.READ_WORKERS)
        inline = []
        def inline_reader(path, *args):
            self.assertEqual(main_thread, threading.get_ident())
            inline.append(path.name)
            return actual(path, *args)
        with mock.patch.object(inventory, "ThreadPoolExecutor", side_effect=
                               AssertionError("inline inventories cannot create reader threads")), \
                mock.patch.object(inventory, "_file_record", side_effect=inline_reader):
            synchronous = self.capture(max_entries=64)
            inventory.close(self.owner, synchronous, max_file=1024, max_entries=64)
        self.assertEqual(original, synchronous)
        self.assertEqual(names + names, inline)

    def test_real_stat_capacity_is_reserved_before_an_excess_file_is_submitted(self):
        self.write("one.bin", b"1234")
        self.write("two.bin", b"5678")
        with mock.patch.object(inventory, "_file_record", wraps=inventory._file_record) as reads:
            with self.assertRaisesRegex(ValueError, "total byte bound"):
                self.capture(max_total=7)
        self.assertLessEqual(reads.call_count, 1)

    def test_owned_directory_final_guard_waits_for_its_active_reader(self):
        self.write("one.bin")
        actual_read, actual_names = inventory._file_record, inventory._names
        active, mutations, scans = threading.Event(), [], []
        def reader(*args):
            active.set()
            try:
                (self.owner / "late-empty").mkdir()
                mutations.append(active.is_set())
                return actual_read(*args)
            finally:
                active.clear()
        def names(directory, maximum):
            if directory == self.owner:
                scans.append(True)
                if len(scans) == 2 and active.is_set():
                    raise AssertionError("directory postguard ran before its reader ended")
            return actual_names(directory, maximum)
        with mock.patch.object(inventory, "_file_record", side_effect=reader), \
                mock.patch.object(inventory, "_names", side_effect=names):
            with self.assertRaisesRegex(ValueError, "immediate directory"):
                self.capture()
        self.assertEqual([True], mutations)
        self.assertEqual(2, len(scans))
        self.assertFalse(active.is_set())

    def test_reader_failure_is_propagated_only_after_all_active_readers_finish(self):
        for index in range(20):
            self.write("%02d.bin" % index)
        actual, lock = inventory._file_record, threading.Lock()
        another_started, release = threading.Event(), threading.Event()
        metrics = {"active": 0, "started": 0, "finished": 0}
        def reader(path, *args):
            with lock:
                metrics["active"] += 1
                metrics["started"] += 1
            try:
                if path.name == "00.bin":
                    if not another_started.wait(1):
                        raise AssertionError("no overlapping reader")
                    raise ValueError("injected physical reader failure")
                another_started.set()
                if not release.wait(2):
                    raise AssertionError("reader cleanup was not released")
                return actual(path, *args)
            finally:
                with lock:
                    metrics["active"] -= 1
                    metrics["finished"] += 1
        timer = threading.Timer(0.05, release.set)
        timer.start()
        try:
            with mock.patch.object(inventory, "READ_WORKERS", 8), \
                    mock.patch.object(inventory, "_file_record", side_effect=reader):
                with self.assertRaisesRegex(ValueError, "injected physical reader failure"):
                    self.capture()
        finally:
            release.set()
            timer.cancel()
            timer.join(timeout=1)
        self.assertGreaterEqual(metrics["started"], 2)
        self.assertEqual(0, metrics["active"])
        self.assertEqual(metrics["started"], metrics["finished"])
        inline = []
        main_thread = threading.get_ident()
        def inline_failure(path, *args):
            self.assertEqual(main_thread, threading.get_ident())
            actual(path, *args)
            inline.append(path.name)
            raise ValueError("injected inline physical reader failure")
        with mock.patch.object(inventory, "ThreadPoolExecutor", side_effect=
                               AssertionError("inline failures cannot create reader threads")), \
                mock.patch.object(inventory, "_file_record", side_effect=inline_failure):
            with self.assertRaisesRegex(ValueError, "inline physical reader failure"):
                self.capture()
        self.assertEqual(["00.bin"], inline)

    def test_parallel_close_retains_original_handle_identity_and_fresh_bytes(self):
        paths = [self.write("%02d.bin" % index) for index in range(8)]
        original = self.capture()
        actual, inode = inventory.os.fstat, paths[-1].stat().st_ino
        def replaced(descriptor):
            info = actual(descriptor)
            return self.info(info, st_ino=info.st_ino + 1) if info.st_ino == inode else info
        with mock.patch.object(inventory.os, "fstat", side_effect=replaced):
            with self.assertRaisesRegex(ValueError, "identity changed"):
                self.close(original)
        paths[-1].write_bytes(b"different raw bytes")
        with self.assertRaisesRegex(ValueError, "raw file changed"):
            self.close(original)


if __name__ == "__main__":
    unittest.main()
