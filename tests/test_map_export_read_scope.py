"""Physical Screen Map export boundaries; document semantics are explicit seams."""

from contextlib import ExitStack
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import screen_map_model
from authoring import stage_tilemap_model as parsed

# Only this public export retains the measured scoped implementation.
MODELS = (screen_map_model,)


class MapExportReadScopeTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="map-export-read-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.make_tree(self.root, 1)

    @staticmethod
    def make_tree(root, value):
        (root / "src").mkdir(parents=True)
        (root / "data").mkdir()
        (root / "src/main.s").write_bytes(b"Value: dc.b " + str(value).encode() + b"\n")

    def seam(self, module, stack, operations, *, mutate=False):
        def export(root, profile, *extra):
            self.assertEqual("jp", profile)
            self.assertEqual((), extra)
            operations.append(parsed._PARSED_OPERATION.get())
            self.assertIsNotNone(operations[-1])
            first = parsed.labelled_blocks(root)[0]["Value"]
            self.assertEqual(first, parsed.labelled_blocks(root)[0]["Value"])
            if mutate:
                path = root / "src/main.s"
                before = path.stat()
                path.write_bytes(b"Value: dc.b 9\n")
                os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
            return {"value": first}

        return stack.enter_context(mock.patch.object(module, "_export_document", side_effect=export))

    def test_every_export_runs_the_body_and_owns_fresh_positional_and_keyword_lifetimes(self):
        for module in MODELS:
            with self.subTest(model=module.__name__), ExitStack() as stack:
                operations = []
                body = self.seam(module, stack, operations)
                parse = stack.enter_context(
                    mock.patch.object(parsed, "_parse_labelled_blocks", wraps=parsed._parse_labelled_blocks)
                )
                first = module.export_document(self.root, "jp")
                first["value"] = b"changed returned document"
                second = module.export_document(root=self.root, profile="jp")
                self.assertEqual({"value": b"\x01"}, second)
                self.assertEqual((2, 2), (body.call_count, parse.call_count))
                self.assertIsNot(operations[0], operations[1])
                self.assertTrue(all(operation.closed for operation in operations))
                self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_each_owned_export_refuses_late_original_drift_before_returning_a_document(self):
        for module in MODELS:
            with self.subTest(model=module.__name__), ExitStack() as stack:
                (self.root / "src/main.s").write_bytes(b"Value: dc.b 1\n")
                operations = []
                body = self.seam(module, stack, operations, mutate=True)
                with self.assertRaisesRegex(ValueError, "raw file changed"):
                    module.export_document(self.root, "jp")
                self.assertEqual(1, body.call_count)
                self.assertTrue(operations[0].closed)
                self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_each_foreign_export_keeps_fresh_reads_without_rebinding_the_primary(self):
        foreign = self.root / "build/staged"
        self.make_tree(foreign, 2)
        for module in MODELS:
            with self.subTest(model=module.__name__), ExitStack() as stack:
                (foreign / "src/main.s").write_bytes(b"Value: dc.b 2\n")
                operations = []
                body = self.seam(module, stack, operations)
                with parsed.parsed_operation(self.root) as primary:
                    self.assertEqual(b"\x01", parsed.labelled_blocks(self.root)[0]["Value"])
                    for value in (2, 3):
                        (foreign / "src/main.s").write_bytes(b"Value: dc.b " + str(value).encode() + b"\n")
                        self.assertEqual({"value": bytes([value])}, module.export_document(foreign, "jp"))
                        self.assertIs(primary, parsed._PARSED_OPERATION.get())
                        self.assertFalse(primary.closed)
                        self.assertEqual({}, primary._readonly_records)
                    self.assertTrue(all(operation is primary for operation in operations))
                self.assertEqual(2, body.call_count)
                self.assertTrue(primary.closed)
                self.assertIsNone(parsed._PARSED_OPERATION.get())


if __name__ == "__main__":
    unittest.main()
