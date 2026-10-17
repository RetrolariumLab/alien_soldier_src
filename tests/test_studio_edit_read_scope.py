"""Physical smoke read lifetimes with real tiny Workspaces and explicit model seams."""
from contextlib import ExitStack
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import sound_studio, text_studio
from authoring import stage_tilemap_model as parsed
from authoring.atomic_output import atomic_write_bytes
from tests.test_sound_studio_state import tiny_documents as sound_documents
from tests.workstation_fixtures import text_documents


class StudioEditReadScopeTests(unittest.TestCase):
    def fixture(self, stack, module, documents, *, mutate=False, empty_apply=False):
        temporary = stack.enter_context(tempfile.TemporaryDirectory(prefix="studio-edit-read-"))
        root = Path(temporary)
        (root / "src").mkdir()
        (root / "data").mkdir()
        source = root / "src/main.s"
        source.write_bytes(b"Value: dc.b 1\n")
        calls, operations, staged_values = [], [], []
        def original():
            operation = parsed._PARSED_OPERATION.get()
            self.assertIsNotNone(operation)
            self.assertEqual(root, operation.requested_root)
            operations.append(operation)
            self.assertEqual(b"\x01", parsed.labelled_blocks(root)[0]["Value"])
            self.assertEqual({}, operation._readonly_records)
        context = {}
        def validate(identifier, document, authority, profile):
            self.assertIs(documents[identifier], document)
            self.assertEqual((root, "jp"), (authority, profile))
            original()
            calls.append((identifier, "validate"))
            if mutate and sum(role == "validate" for _, role in calls) == 2 * len(documents):
                before = source.stat()
                source.write_bytes(b"Value: dc.b 2\n")
                os.utime(source, ns=(before.st_atime_ns, before.st_mtime_ns))
        def apply(identifier, document, destination, profile, validation_root):
            self.assertIs(documents[identifier], document)
            self.assertEqual((root, "jp"), (validation_root, profile))
            original()
            calls.append((identifier, "apply"))
            before = parsed.labelled_blocks(destination)[0]["Value"][0]
            atomic_write_bytes(destination / "src/main.s", b"Value: dc.b " + str(before + 1).encode() + b"\n")
            after = parsed.labelled_blocks(destination)[0]["Value"][0]
            staged_values.append((before, after))
            self.assertEqual(before + 1, after)
            return [] if empty_apply else ["src/main.s"]
        for identifier, document in documents.items():
            context[identifier] = {"document": document,
                "validate": lambda doc, authority, profile, identifier=identifier:
                    validate(identifier, doc, authority, profile),
                "apply": lambda doc, destination, profile, validation_root, identifier=identifier:
                    apply(identifier, doc, destination, profile, validation_root)}
        def load(project, profile):
            self.assertEqual((root, "jp"), (project, profile))
            # Retain the real load_context's existing nested primary lifetime.
            with parsed.parsed_operation(project):
                original()
            return context
        def stage(project, destination):
            self.assertEqual(root, project)
            self.assertTrue(destination.is_relative_to(root / "build/content"))
            (destination / "src").mkdir(parents=True)
            (destination / "data").mkdir()
            atomic_write_bytes(destination / "src/main.s", b"Value: dc.b 2\n")
        stack.enter_context(mock.patch.object(module, "load_context", side_effect=load))
        stack.enter_context(mock.patch.object(module, "stage_tree", side_effect=stage))
        return root, source, calls, operations, staged_values

    def test_both_smokes_repeat_all_validators_and_read_each_real_staged_write_fresh(self):
        for module, factory in ((sound_studio, sound_documents), (text_studio, text_documents)):
            with self.subTest(studio=module.__name__), ExitStack() as stack:
                documents = factory()
                root, source, calls, operations, values = self.fixture(stack, module, documents)
                module.check(project=root, profile="jp")
                expected = [(identifier, role) for identifier in sorted(documents)
                            for role in ("validate", "apply", "validate")]
                self.assertEqual(expected, calls)
                self.assertEqual([(n, n + 1) for n in range(2, 2 + len(documents))], values)
                self.assertTrue(all(operation is operations[0] for operation in operations))
                self.assertTrue(operations[0].closed)
                self.assertEqual(b"Value: dc.b 1\n", source.read_bytes())
                self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_late_original_drift_after_every_callback_refuses_at_the_final_closer(self):
        for module, factory in ((sound_studio, sound_documents), (text_studio, text_documents)):
            with self.subTest(studio=module.__name__), ExitStack() as stack:
                documents = factory()
                root, _, calls, operations, _ = self.fixture(stack, module, documents, mutate=True)
                with self.assertRaisesRegex(ValueError, "raw file changed"):
                    module.check(root, "jp")
                self.assertEqual(3 * len(documents), len(calls))
                self.assertTrue(operations[0].closed)
                self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_an_empty_apply_keeps_the_original_failure_and_closes_before_return(self):
        for module, factory in ((sound_studio, sound_documents), (text_studio, text_documents)):
            with self.subTest(studio=module.__name__), ExitStack() as stack:
                root, _, calls, operations, _ = self.fixture(stack, module, factory(), empty_apply=True)
                with self.assertRaisesRegex(ValueError, "smoke edit changed no source"):
                    module.check(root, "jp")
                self.assertEqual(["validate", "apply"], [role for _, role in calls])
                self.assertTrue(operations[0].closed)
                self.assertIsNone(parsed._PARSED_OPERATION.get())


if __name__ == "__main__":
    unittest.main()
