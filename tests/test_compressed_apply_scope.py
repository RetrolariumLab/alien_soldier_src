"""Tiny physical apply-read boundaries; codec/model semantics are explicit seams."""

from contextlib import ExitStack
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import compressed_graphics_model as model
from authoring import stage_tilemap_model as parsed
from authoring import atomic_output


class CompressedApplyScopeTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="compressed-apply-scope-")
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.root = self.base / "staged"
        self.make_tree(self.root, b"one")
        self.payload = self.root / "data/blob.bin"
        self.document = {"payloads": [{"name": "Blob", "path": "data/blob.bin", "codec": "lzss", "storage": "payload"}]}

    @staticmethod
    def make_tree(root, body):
        (root / "src").mkdir(parents=True)
        (root / "data").mkdir()
        (root / "src/main.s").write_bytes(b'Blob: binclude "data/blob.bin"\n')
        (root / "data/blob.bin").write_bytes(body)

    def semantics(self, stack, *, after_read=None, before_write=None):
        operations, observed = [], []

        def validate(document, root, profile):
            self.assertIs(document, self.document)
            self.assertEqual((self.root, "jp"), (root, profile))
            operations.append(parsed._PARSED_OPERATION.get())
            first = parsed.labelled_blocks(root)[0]["Blob"]
            self.assertEqual(first, parsed.labelled_blocks(root)[0]["Blob"])
            observed.append(first)
            if after_read:
                after_read()

        actual = atomic_output.atomic_write_bytes

        def write(path, body):
            self.assertEqual((self.payload, b"two"), (path, body))
            if before_write:
                before_write(operations[-1])
            return actual(path, body)

        validator = stack.enter_context(mock.patch.object(model, "validate_document", side_effect=validate))
        stack.enter_context(mock.patch.object(model, "decompress_as_vram", side_effect=lambda raw: raw))
        stack.enter_context(mock.patch.object(model, "payload_plain", return_value=b"two"))
        encoder = stack.enter_context(mock.patch.object(model, "encoded_slot", return_value=b"two"))
        writer = stack.enter_context(mock.patch.object(atomic_output, "atomic_write_bytes", side_effect=write))
        return operations, observed, validator, encoder, writer

    def test_original_parse_is_shared_and_physically_closed_before_the_real_writer(self):
        def closed(operation):
            self.assertTrue(operation.closed)
            self.assertIsNone(parsed._PARSED_OPERATION.get())

        with ExitStack() as stack:
            operations, observed, validate, encode, writer = self.semantics(stack, before_write=closed)
            parse = stack.enter_context(
                mock.patch.object(parsed, "_parse_labelled_blocks", wraps=parsed._parse_labelled_blocks)
            )
            self.assertEqual(["data/blob.bin"], model.apply_document(self.document, self.root, "jp"))
            self.assertEqual(1, parse.call_count)
            self.assertEqual([b"one"], observed)
            self.assertTrue(operations[0].closed)
            self.assertEqual((1, 1, 1), (validate.call_count, encode.call_count, writer.call_count))
        self.assertEqual(b"two", self.payload.read_bytes())
        self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_late_same_size_original_rewrite_refuses_before_encoding_or_any_writer(self):
        def late():
            before = self.payload.stat()
            self.payload.write_bytes(b"bad")
            os.utime(self.payload, ns=(before.st_atime_ns, before.st_mtime_ns))

        with ExitStack() as stack:
            operations, _, validate, encode, writer = self.semantics(stack, after_read=late)
            with self.assertRaisesRegex(ValueError, "raw file changed"):
                model.apply_document(self.document, self.root, "jp")
            self.assertEqual(1, validate.call_count)
            encode.assert_not_called()
            writer.assert_not_called()
            self.assertTrue(operations[0].closed)
        self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_same_root_dry_applies_join_but_repeat_all_model_callbacks(self):
        with ExitStack() as stack:
            operations, observed, validate, encode, writer = self.semantics(stack)
            with parsed.parsed_operation(self.root) as outer:
                for _ in range(2):
                    self.assertEqual(
                        ["data/blob.bin"], model.apply_document(self.document, self.root, "jp", write=False)
                    )
                    self.assertIs(outer, parsed._PARSED_OPERATION.get())
                    self.assertFalse(outer.closed)
                self.assertTrue(all(operation is outer for operation in operations))
            self.assertTrue(outer.closed)
            self.assertEqual([b"one", b"one"], observed)
            self.assertEqual((2, 2, 0), (validate.call_count, encode.call_count, writer.call_count))
        self.assertEqual(b"one", self.payload.read_bytes())
        self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_foreign_scope_keeps_fresh_staged_reads_and_original_primary_lifetime(self):
        primary = self.base / "primary"
        self.make_tree(primary, b"old")
        with ExitStack() as stack:
            operations, observed, validate, encode, writer = self.semantics(stack)
            with parsed.parsed_operation(primary) as outer:
                parsed.labelled_blocks(primary)
                self.assertEqual(["data/blob.bin"], model.apply_document(self.document, self.root, "jp"))
                self.assertEqual([], model.apply_document(self.document, self.root, "jp"))
                self.assertEqual([b"one", b"two"], observed)
                self.assertTrue(all(operation is outer for operation in operations))
                self.assertEqual(b"old", parsed.labelled_blocks(primary)[0]["Blob"])
                self.assertIs(outer, parsed._PARSED_OPERATION.get())
                self.assertFalse(outer.closed)
            self.assertEqual((2, 1, 1), (validate.call_count, encode.call_count, writer.call_count))
        self.assertTrue(outer.closed)
        self.assertIsNone(parsed._PARSED_OPERATION.get())


if __name__ == "__main__":
    unittest.main()
