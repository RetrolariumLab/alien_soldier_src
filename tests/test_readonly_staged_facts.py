"""Tiny original-byte controls for explicitly readonly, operation-local stages."""

from copy import deepcopy
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import guarded_inventory as inventory
from authoring import stage_tilemap_model as model


class ReadonlyStagedFactsTests(unittest.TestCase):
    def setUp(self):
        base = ROOT / "build/test-fixtures/readonly-staged-facts"
        base.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix="owner-", dir=base)
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.owner = self.root / "build/content/jp/source-format-builds/batch-jp-fixture"
        self.baseline, self.edited = (self.owner / name / "tree" for name in ("baseline", "edited"))
        self.other = self.root / "build/unlisted/tree"
        for tree, version in ((self.root, 0x10), (self.baseline, 0x20), (self.edited, 0x30), (self.other, 0x40)):
            self.write_tree(tree, version)
        self.labels = ("baseline", "edited")
        self.frozen = self.capture()

    @staticmethod
    def write_tree(tree, version):
        (tree / "src/nested").mkdir(parents=True, exist_ok=True)
        (tree / "src/empty").mkdir(exist_ok=True)
        (tree / "data/empty").mkdir(parents=True, exist_ok=True)
        (tree / "config").mkdir(exist_ok=True)
        (tree / "src/a.s").write_bytes(
            (
                'Bytes: dc.b $%02X,-1\r\nBlob: binclude "data/blob.bin"\r\n'
                "Duplicate: dc.w %d\r\nAssets:\r\n dc.w 6\r\n dc.l Blob\r\n"
                " dc.w $4000\r\n dc.w $FFFF\r\n"
                "Gfx_FixtureVRAMTransferParameters: dc.l $%X,$FFFF6000,$FFFF4000,$4000\r\n"
                % (version, version, 0xFFFF7000 + version)
            ).encode()
        )
        (tree / "src/nested/z.s").write_bytes(("Duplicate: dc.w %d\nLast: dc.b 7\n" % (version + 1)).encode())
        (tree / "data/blob.bin").write_bytes(bytes(range(version, version + 8)))
        (tree / "config/marker.json").write_bytes(b'{"marker":"original"}\n')

    def capture(self):
        return inventory.capture(self.owner, max_file=1 << 20, max_total=1 << 20, max_entries=1000)

    def scope(self, frozen=None, labels=None):
        return model._readonly_staged_facts(
            self.root, self.owner, self.frozen if frozen is None else frozen, self.labels if labels is None else labels
        )

    @staticmethod
    def read(tree):
        data, bodies = model.labelled_blocks(tree)
        return (
            data,
            bodies,
            model.read_asset_lists(tree, bodies),
            model.read_descriptors(tree),
            tuple(model.source_texts(tree)),
        )

    def change_same_size(self, path):
        before, body = path.stat(), path.read_bytes()
        path.write_bytes(bytes([body[0] ^ 1]) + body[1:])
        os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
        self.assertEqual(before.st_size, path.stat().st_size)
        self.assertEqual(before.st_mtime_ns, path.stat().st_mtime_ns)

    @staticmethod
    def total(records):
        return sum(row[1] for row in records.values() if row[0] == "file")

    def test_registered_roots_share_only_original_facts_and_return_isolated_values(self):
        expected = {tree: self.read(tree) for tree in (self.root, self.baseline, self.edited)}
        with mock.patch.object(model, "_parse_labelled_blocks", wraps=model._parse_labelled_blocks) as parse:
            with model.parsed_operation(self.root) as primary:
                with self.scope():
                    edited = self.read(self.edited)  # Staged first must not capture primary ROOT.
                    self.assertEqual((), primary._owners)
                    self.assertEqual(2, len(primary._readonly_owners))
                    for tree in (self.root, self.baseline, self.edited, self.baseline, self.root):
                        actual = self.read(tree)
                        self.assertEqual(expected[tree], actual)
                        self.assertEqual(
                            [list(value) for value in expected[tree][:4]], [list(value) for value in actual[:4]]
                        )
                    self.assertEqual(2, len(primary._owners))
                    self.assertEqual(4, len(primary._readonly_owners))
                    self.assertEqual(bytes(range(0x33, 0x36)), edited[0]["Blob"][3:6])
                    self.assertEqual((0x31,), edited[0]["Duplicate"])
                    edited[0]["Blob"], edited[1]["Assets"] = b"forged", ()
                    edited[2].clear()
                    edited[3]["Gfx_FixtureVRAMTransferParameters"].coarse = 0
                    self.assertEqual(expected[self.edited], self.read(self.edited))
                    self.assertEqual(3, parse.call_count)
                self.assertIsNone(primary._readonly)
            self.assertIsNone(model._PARSED_OPERATION.get())

    def test_unlisted_and_outside_roots_stay_fresh_and_custom_bodies_stay_lazy(self):
        custom = {"Assets": (" dc.w 6", " dc.l Blob", " dc.w $4000", " dc.w $FFFF")}
        expected_custom = model._parse_asset_lists(custom)
        with model.parsed_operation(self.root) as primary:
            # The factory freezes plain rows, but unused trees trigger no physical lookup.
            lazy = self.scope(frozen={})
            with (
                mock.patch.object(inventory, "_owner", side_effect=AssertionError("unexpected IO")),
                mock.patch.object(Path, "open", side_effect=AssertionError("unexpected open")),
            ):
                with lazy:
                    self.assertEqual(expected_custom, model.read_asset_lists(self.baseline, custom))
                    self.assertEqual({}, primary._readonly["facts"])
            self.assertEqual((), primary._readonly_owners)
            with self.scope():
                with self.assertRaisesRegex(ValueError, "mix preservation roots"):
                    with model.parsed_operation(self.baseline):
                        self.fail("public wrong-root scope was admitted")
                for sentinel in (None, object()):
                    with self.subTest(sentinel=type(sentinel).__name__):

                        def outcome(function):
                            try:
                                function(sentinel)
                            except Exception as error:
                                return type(error), str(error)
                            self.fail("sentinel unexpectedly produced ROOT facts")

                        self.assertEqual(outcome(model._parse_labelled_blocks), outcome(model.labelled_blocks))
                first = self.read(self.other)
                (self.other / "data/blob.bin").write_bytes(b"new external facts")
                self.assertNotEqual(first, self.read(self.other))
            first = self.read(self.baseline)  # Outside explicit registry remains legacy fresh.
            (self.baseline / "data/blob.bin").write_bytes(b"fresh outside scope")
            self.assertNotEqual(first, self.read(self.baseline))
        self.assertIsNone(model._PARSED_OPERATION.get())

    def test_census_is_frozen_before_callbacks_and_later_same_path_cannot_rebind(self):
        supplied = deepcopy(self.frozen)
        frozen_scope = self.scope(supplied)
        supplied["baseline/tree/data/blob.bin"]["sha256"] = "0" * 64
        with model.parsed_operation(self.root) as primary:
            with frozen_scope:
                original = self.read(self.baseline)
            replacement = deepcopy(self.frozen)
            replacement["baseline/tree/data/blob.bin"]["sha256"] = "0" * 64
            with self.scope(replacement):
                with self.assertRaisesRegex(ValueError, "conflict.*no rebind"):
                    self.read(self.baseline)
                self.assertEqual({}, primary._readonly["facts"])
            self.assertEqual(bytes(range(0x20, 0x28)), original[0]["Blob"])
        for change, pattern in (
            ("hash", "ORIGINAL"),
            ("alias", "alias spelling"),
            ("missing", "absent from its ORIGINAL"),
        ):
            malformed = deepcopy(self.frozen)
            if change == "hash":
                malformed["baseline/tree/data/blob.bin"]["sha256"] = "0" * 64
            elif change == "alias":
                malformed["baseline/tree/src/../alias.s"] = {"kind": "directory"}
            else:
                del malformed["baseline/tree/data"]
            with self.subTest(change=change):
                if change == "hash":
                    # A published ORIGINAL anchor is never cleared after its
                    # first physical read fails: outer close must refuse too.
                    with self.assertRaisesRegex(ValueError, "raw file changed"):
                        with model.parsed_operation(self.root):
                            with self.scope(malformed):
                                with self.assertRaisesRegex(ValueError, pattern):
                                    self.read(self.baseline)
                else:
                    with model.parsed_operation(self.root):
                        with self.scope(malformed):
                            with self.assertRaisesRegex(ValueError, pattern):
                                self.read(self.baseline)
                self.assertIsNone(model._PARSED_OPERATION.get())

    def test_combined_bounds_cover_staged_first_and_primary_first_without_partial_reuse(self):
        with model.parsed_operation(self.root) as primary:
            with self.scope():
                self.read(self.root)
                self.read(self.baseline)
                primary_bytes = self.total(primary._records)
                staged_bytes = self.total(primary._readonly_records)
                primary_entries, staged_entries = len(primary._records), len(primary._readonly_records)
        for bound, limit in (
            ("_PARSED_MAX_TOTAL", primary_bytes + staged_bytes - 1),
            ("_PARSED_MAX_ENTRIES", primary_entries + staged_entries - 1),
        ):
            frozen_scope = self.scope()  # Freeze full owner before setting an intentionally tiny joint cap.
            with self.subTest(order="primary-first", bound=bound), model.parsed_operation(self.root) as primary:
                self.read(self.root)
                with mock.patch.object(model, bound, limit):
                    with frozen_scope:
                        with self.assertRaisesRegex(ValueError, "combined parsed source"):
                            self.read(self.baseline)
                        self.assertEqual({}, primary._readonly["facts"])
                        self.assertEqual((), primary._readonly_owners)
                        self.assertTrue(self.read(self.root))
            frozen_scope = self.scope()
            with self.subTest(order="staged-first", bound=bound), model.parsed_operation(self.root) as primary:
                with frozen_scope:
                    self.read(self.baseline)
                    with mock.patch.object(model, bound, limit):
                        with self.assertRaisesRegex(ValueError, "combined parsed source"):
                            self.read(self.root)
                        self.assertTrue(primary._budget_failed)
                        with self.assertRaisesRegex(ValueError, "combined parsed source"):
                            self.read(self.baseline)
                # Bounds no longer patched; ORIGINAL closure still runs after partial primary capture.

    def test_scope_lifetime_pid_errors_and_sibling_outputs_do_not_rebind_source(self):
        with model.parsed_operation(self.root) as primary:
            with self.scope():
                self.read(self.baseline)
                child = primary._readonly["facts"][self.baseline]
                with self.assertRaisesRegex(ValueError, "cannot recapture"):
                    child._capture()
                with self.assertRaisesRegex(ValueError, "cannot overlap"):
                    with self.scope():
                        self.fail("overlapping registry admitted")
                with mock.patch.object(model.os, "getpid", return_value=child.pid + 1):
                    with self.assertRaisesRegex(ValueError, "outside its owning scope"):
                        self.read(self.baseline)
                self.assertTrue(self.read(self.baseline))
            with self.assertRaisesRegex(ValueError, "closed"):
                child.blocks()
            for relative in (
                "batch.json",
                "baseline/image.p",
                "baseline/image.lst",
                "baseline/tree/config/marker.json",
            ):
                (self.owner / relative).write_bytes(b"legitimate sibling output update")
            with self.assertRaisesRegex(RuntimeError, "original callback failure"):
                with self.scope():
                    self.read(self.baseline)
                    raise RuntimeError("original callback failure")
            self.assertIsNone(primary._readonly)
            self.assertTrue(self.read(self.root))
        with self.assertRaisesRegex(ValueError, "closed"):
            primary.blocks()
        self.assertIsNone(model._PARSED_OPERATION.get())

    def test_external_include_falls_back_fresh_without_reusing_external_bytes(self):
        external = self.baseline / "external/blob.bin"
        external.parent.mkdir()
        external.write_bytes(b"one")
        (self.baseline / "src/external.s").write_bytes(b'Outside: binclude "external/blob.bin"\n')
        self.frozen = self.capture()
        with model.parsed_operation(self.root):
            with (
                self.scope(),
                mock.patch.object(model, "_parse_labelled_blocks", wraps=model._parse_labelled_blocks) as parse,
            ):
                before = self.read(self.baseline)
                external.write_bytes(b"two")
                after = self.read(self.baseline)
                self.assertEqual(b"one", before[0]["Outside"])
                self.assertEqual(b"two", after[0]["Outside"])
                self.assertEqual(3, parse.call_count)  # One guarded attempt, then two genuine legacy parses.
        self.assertIsNone(model._PARSED_OPERATION.get())

    def test_original_hardlink_drift_and_factory_scope_roots_are_refused(self):
        path, link = self.baseline / "data/blob.bin", self.owner / "temporary-hardlink.bin"
        try:
            with self.assertRaisesRegex(ValueError, "hard-linked"):
                with model.parsed_operation(self.root):
                    with self.scope():
                        self.read(self.baseline)
                    os.link(path, link)
        finally:
            if link.exists():
                link.unlink()
        with self.assertRaisesRegex(ValueError, "exact primary root scope"):
            with self.scope():
                self.fail("registry without primary admitted")
        with model.parsed_operation(self.root):
            for labels in (("baseline", "BASELINE"), ("../baseline",), ("baseline/tree",)):
                with self.subTest(labels=labels), self.assertRaisesRegex(ValueError, "fixed canonical"):
                    with self.scope(labels=labels):
                        self.fail("noncanonical labels admitted")
            with self.assertRaisesRegex(ValueError, "fixed canonical"):
                with model._readonly_staged_facts(self.root, self.root / "outside", {}, self.labels):
                    self.fail("owner outside ROOT/build admitted")


if __name__ == "__main__":
    unittest.main()
