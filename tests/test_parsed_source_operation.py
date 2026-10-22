"""Tiny physical ORIGINAL parser sharing controls; no ROM/tool/native runs."""

import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import stage_tilemap_model as model
from authoring import compressed_graphics_model as graphics
from authoring import object_sprite_model as sprites


def legacy_source_indices(root):
    """Frozen original three read/regex/split algorithms, not cached verdicts."""
    paths, owners, lines, index = {}, {}, {}, {}
    for path in sorted((root / "src").rglob("*.s")):
        for line in path.read_text(encoding="utf-8").splitlines():
            match = graphics.BINCLUDE.match(line)
            if match:
                paths[match.group(1)] = match.group(2)
    for path in sorted((root / "src").rglob("*.s")):
        relative = path.relative_to(root).as_posix()
        for line in path.read_text(encoding="utf-8").splitlines():
            match = graphics.LABEL.match(line)
            if match:
                owners[match.group(1)] = relative
    for path in sorted(root.joinpath(model.SOURCE_ROOT).rglob("*.s")):
        text = path.read_text(encoding="utf-8").split("\n")
        lines[path] = text
        for number, line in enumerate(text):
            head = sprites.LABEL_LINE.match(line)
            if head and head.group("name") not in index:
                index[head.group("name")] = (path, number)
    return paths, owners, (lines, index)


class ParsedSourceOperationTests(unittest.TestCase):
    def setUp(self):
        base = ROOT / "build/test-fixtures/parsed-source-operation"
        base.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix="owner-", dir=base)
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.source = self.write(
            "src/first.s",
            b"Bytes: dc.b $01,-$1,3\n"
            b'Words: dc.w $1234,-2\nBlob: binclude "data/blob.bin"\n'
            b'Unsupported: dc.b symbol\nMissing: binclude "data/absent.bin"\n',
        )
        self.payload = self.write("data/blob.bin", b"\x12\x34\x56")
        self.write("src/nested/last.s", b"Bytes: dc.b 9\nCode: move.w d0,d1\n")
        (self.root / "src/empty").mkdir()
        (self.root / "data/empty").mkdir()

    def write(self, relative, body):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(body)
        return path

    def change_same_size(self, path):
        before = path.stat()
        body = path.read_bytes()
        path.write_bytes(bytes([body[0] ^ 1]) + body[1:])
        os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
        self.assertEqual(before.st_size, path.stat().st_size)
        self.assertEqual(before.st_mtime_ns, path.stat().st_mtime_ns)

    def test_cached_and_uncached_results_and_order_match_for_all_newlines(self):
        original = self.source.read_bytes()
        for newline in (b"\n", b"\r\n", b"\r"):
            with self.subTest(newline=newline):
                self.source.write_bytes(original.replace(b"\n", newline))
                expected = model.labelled_blocks(self.root)
                with model.parsed_operation(self.root):
                    actual = model.labelled_blocks(self.root)
                    self.assertEqual(expected, actual)
                    self.assertEqual([list(item) for item in expected], [list(item) for item in actual])
                self.assertEqual(b"\x09", actual[0]["Bytes"])
                self.assertEqual((0x1234, -2), actual[0]["Words"])
                self.assertNotIn("Unsupported", actual[0])
                self.assertNotIn("Missing", actual[0])

    def test_one_scope_parses_once_and_returns_isolated_dicts(self):
        with mock.patch.object(model, "_parse_labelled_blocks", wraps=model._parse_labelled_blocks) as parse:
            with model.parsed_operation(self.root):
                first = model.labelled_blocks(self.root)
                first[0]["Blob"] = b"changed return value"
                first[1].clear()
                second = model.labelled_blocks(self.root)
                self.assertEqual(b"\x12\x34\x56", second[0]["Blob"])
                self.assertIn("Code", second[1])
                self.assertEqual(1, parse.call_count)
            model.labelled_blocks(self.root)
            self.assertEqual(2, parse.call_count)

    def test_capture_is_lazy_and_early_refusals_keep_their_original_error(self):
        @model.with_parsed_operation
        def refuse(root, profile):
            raise TypeError("original profile refusal")

        with mock.patch.object(model.guarded_inventory, "capture", wraps=model.guarded_inventory.capture) as capture:
            with model.parsed_operation(object()):
                pass
            with self.assertRaisesRegex(TypeError, "original profile refusal"):
                refuse(object(), "unsupported")
            self.assertEqual(0, capture.call_count)
        self.assertEqual("refuse", refuse.__name__)
        with self.assertRaises(TypeError):
            refuse(profile="unsupported")

    def test_bounds_apply_to_both_complete_owners(self):
        with mock.patch.object(model.guarded_inventory, "capture", wraps=model.guarded_inventory.capture) as capture:
            with model.parsed_operation(self.root):
                model.labelled_blocks(self.root)
        self.assertEqual([self.root / "src", self.root / "data"], [call.args[0] for call in capture.call_args_list])
        for call in capture.call_args_list:
            self.assertEqual(128 << 20, call.kwargs["max_file"])
            self.assertEqual(512 << 20, call.kwargs["max_total"])
            self.assertEqual(32768, call.kwargs["max_entries"])

    def test_late_same_size_source_and_payload_drift_cannot_pass_final_close(self):
        for relative in ("src/first.s", "data/blob.bin"):
            path, original = self.root / relative, (self.root / relative).read_bytes()
            with self.subTest(relative=relative):
                with self.assertRaisesRegex(ValueError, "raw file changed"):
                    with model.parsed_operation(self.root):
                        model.labelled_blocks(self.root)
                        self.change_same_size(path)
                path.write_bytes(original)
                self.assertIsNone(model._PARSED_OPERATION.get())

    def test_added_source_and_empty_directory_cannot_pass_final_close(self):
        for relative, body in (("src/late.s", b"Late: dc.b 7\n"), ("data/empty/late", None)):
            path = self.root / relative
            with self.subTest(relative=relative):
                with self.assertRaisesRegex(ValueError, "directory inventory changed"):
                    with model.parsed_operation(self.root):
                        model.labelled_blocks(self.root)
                        path.mkdir() if body is None else path.write_bytes(body)
                path.rmdir() if body is None else path.unlink()

    def test_each_scope_uses_fresh_physical_source_facts(self):
        with model.parsed_operation(self.root):
            before = model.labelled_blocks(self.root)
        self.payload.write_bytes(b"\x65\x43\x21")
        with model.parsed_operation(self.root):
            after = model.labelled_blocks(self.root)
        self.assertNotEqual(before[0]["Blob"], after[0]["Blob"])
        self.assertEqual(model.labelled_blocks(self.root), after)

    def test_matching_nested_scope_joins_and_closed_object_cannot_be_reused(self):
        with model.parsed_operation(self.root) as outer:
            with model.parsed_operation(root=self.root) as inner:
                self.assertIs(outer, inner)
                model.labelled_blocks(self.root)
            self.assertFalse(outer.closed)
            with self.assertRaisesRegex(ValueError, "mix preservation roots"):
                with model.parsed_operation(self.root / "other"):
                    self.fail("unrelated operation was admitted")
        self.assertTrue(outer.closed)
        self.assertIsNone(model._PARSED_OPERATION.get())
        with self.assertRaisesRegex(ValueError, "closed"):
            outer.blocks()

    def test_other_staged_root_is_always_fresh_inside_original_scope(self):
        staged = self.root / "build/staged"
        (staged / "src").mkdir(parents=True)
        source = staged / "src/staged.s"
        source.write_bytes(b"Stage: dc.b 1\n")
        with model.parsed_operation(self.root):
            original = model.labelled_blocks(self.root)
            first = model.labelled_blocks(staged)
            source.write_bytes(b"Stage: dc.b 2\n")
            second = model.labelled_blocks(staged)
            self.assertEqual(b"\x01", first[0]["Stage"])
            self.assertEqual(b"\x02", second[0]["Stage"])
            self.assertEqual(original, model.labelled_blocks(self.root))

    def test_outside_include_falls_back_without_reusing_its_bytes(self):
        outside = self.write("external/blob.bin", b"one")
        self.write("src/external.s", b'Outside: binclude "external/blob.bin"\n')
        with (
            model.parsed_operation(self.root),
            mock.patch.object(model, "_parse_labelled_blocks", wraps=model._parse_labelled_blocks) as parse,
        ):
            first = model.labelled_blocks(self.root)
            outside.write_bytes(b"two")
            second = model.labelled_blocks(self.root)
            self.assertEqual(b"one", first[0]["Outside"])
            self.assertEqual(b"two", second[0]["Outside"])
            self.assertEqual(3, parse.call_count)  # First captured attempt + two fresh calls.

    def test_absolute_outside_include_also_keeps_the_legacy_fresh_path(self):
        outside = self.write("external/blob.bin", b"one")
        self.write("src/external.s", ('Absolute: binclude "%s"\n' % outside.as_posix()).encode())
        expected = model.labelled_blocks(self.root)
        with model.parsed_operation(self.root):
            self.assertEqual(expected, model.labelled_blocks(self.root))
            outside.write_bytes(b"two")
            self.assertEqual(b"two", model.labelled_blocks(self.root)[0]["Absolute"])

    def test_bytes_used_for_parse_must_match_original_capture(self):
        actual, calls = model.guarded_inventory.capture, []

        def mutate_after_capture(owner, **kwargs):
            record = actual(owner, **kwargs)
            calls.append(owner)
            if owner == self.root / "data":
                self.change_same_size(self.payload)
            return record

        with mock.patch.object(model.guarded_inventory, "capture", side_effect=mutate_after_capture):
            with self.assertRaises(ValueError):
                with model.parsed_operation(self.root):
                    model.labelled_blocks(self.root)
        self.assertEqual(2, len(calls))
        self.assertIsNone(model._PARSED_OPERATION.get())

    def test_exception_cleans_scope_and_still_closes_original_inputs(self):
        with self.assertRaisesRegex(RuntimeError, "original callback failure"):
            with model.parsed_operation(self.root):
                model.labelled_blocks(self.root)
                raise RuntimeError("original callback failure")
        self.assertIsNone(model._PARSED_OPERATION.get())
        with self.assertRaisesRegex(ValueError, "raw file changed"):
            with model.parsed_operation(self.root):
                model.labelled_blocks(self.root)
                self.change_same_size(self.payload)
                raise RuntimeError("callback must not hide physical drift")
        self.assertIsNone(model._PARSED_OPERATION.get())

    def test_decorator_covers_positional_and_keyword_root_and_late_callbacks(self):
        @model.with_parsed_operation
        def operation(root, callback=None):
            result = model.labelled_blocks(root)
            if callback:
                callback()
            return result

        self.assertEqual(operation(self.root), operation(root=self.root))
        with self.assertRaisesRegex(ValueError, "raw file changed"):
            operation(self.root, lambda: self.change_same_size(self.payload))
        self.assertIsNone(model._PARSED_OPERATION.get())

    def test_shared_corpus_preserves_old_index_wire_newlines_and_duplicate_rules(self):
        text = (
            'Duplicate: binclude "data/blob.bin"\n'
            'Duplicate: binclude "data/other.bin"\n'
            'Separate:\n    binclude "data/blob.bin"\n'
            "BeforeVT: dc.b 1\vSplitOnly: dc.b 2\n"
            "BeforeUnicode: dc.b 3\u2028UnicodeSplitOnly: dc.b 4\n"
        )
        self.write("data/other.bin", b"other")
        self.write("src/nested/last.s", b'Duplicate: binclude "data/other.bin"\n')
        for newline in ("\n", "\r\n", "\r"):
            self.source.write_bytes(text.replace("\n", newline).encode("utf-8"))
            for root in (self.root, Path(os.path.relpath(self.root, Path.cwd()))):
                with self.subTest(newline=newline, root=root):
                    expected = legacy_source_indices(root)
                    with model.parsed_operation(root):
                        actual = (graphics.source_paths(root), graphics.source_owners(root), sprites.source_index(root))
                        self.assertEqual(expected, actual)
                        self.assertEqual([list(item) for item in expected[:2]], [list(item) for item in actual[:2]])
                        self.assertEqual(list(expected[2][0]), list(actual[2][0]))
                        self.assertEqual(list(expected[2][1]), list(actual[2][1]))
                        self.assertEqual("data/other.bin", actual[0]["Duplicate"])
                        self.assertEqual("src/nested/last.s", actual[1]["Duplicate"])
                        self.assertEqual((root / "src/first.s", 0), actual[2][1]["Duplicate"])
                        self.assertEqual("", actual[2][0][root / "src/first.s"][-1])
                        self.assertIn("SplitOnly", actual[1])
                        self.assertIn("UnicodeSplitOnly", actual[1])
                        self.assertNotIn("SplitOnly", actual[2][1])
                        self.assertNotIn("UnicodeSplitOnly", actual[2][1])

    def test_all_consumers_read_one_original_corpus_and_return_mutable_copies_only(self):
        actual_bytes, actual_open = model._ParsedSourceOperation._bytes, Path.open
        reads, opened = [], []

        def corpus_read(operation, path):
            reads.append(path)
            return actual_bytes(operation, path)

        def physical_open(path, *args, **kwargs):
            opened.append(path)
            return actual_open(path, *args, **kwargs)

        sources = sorted((self.root / "src").rglob("*.s"))
        with (
            mock.patch.object(model._ParsedSourceOperation, "_bytes", corpus_read),
            mock.patch.object(Path, "open", physical_open),
        ):
            with model.parsed_operation(self.root):
                text = tuple(model.source_texts(self.root))
                graphics.source_paths(self.root)
                graphics.source_owners(self.root)
                before = sprites.source_index(self.root)
                model.labelled_blocks(self.root)
                before[0][sources[0]].clear()
                before[1].clear()
                after = sprites.source_index(self.root)
                self.assertTrue(after[0][sources[0]])
                self.assertTrue(after[1])
                self.assertEqual(text, tuple(model.source_texts(self.root)))
        self.assertEqual(sources, [path for path in reads if path.suffix == ".s"])
        for path in sources:
            # Exactly one corpus read, plus mandatory ORIGINAL capture/close.
            self.assertEqual(3, opened.count(path))

    def test_each_corpus_consumer_retains_original_late_byte_and_directory_guards(self):
        consumers = (graphics.source_paths, graphics.source_owners, sprites.source_index)
        for consumer in consumers:
            for relative in ("src/first.s", "data/blob.bin", "src/late.s", "data/empty/late"):
                path = self.root / relative
                before = path.read_bytes() if path.is_file() else None
                with self.subTest(consumer=consumer.__name__, relative=relative):
                    with self.assertRaises(ValueError):
                        with model.parsed_operation(self.root):
                            consumer(self.root)  # This is the FIRST and only input reader.
                            if before is not None:
                                self.change_same_size(path)
                            elif relative.endswith(".s"):
                                path.write_bytes(b"Late: dc.b 7\n")
                            else:
                                path.mkdir()
                    if before is not None:
                        path.write_bytes(before)
                    elif path.is_dir():
                        path.rmdir()
                    else:
                        path.unlink()

    def test_source_text_consumers_stay_fresh_outside_scope_and_for_staged_roots(self):
        consumers = (graphics.source_paths, graphics.source_owners, sprites.source_index)
        staged = self.root / "build/staged"
        (staged / "src").mkdir(parents=True)
        source = staged / "src/first.s"
        first, second = b'Before: binclude "data/one.bin"\n', b'After: binclude "data/two.bin"\n'
        for consumer in consumers:
            with self.subTest(consumer=consumer.__name__):
                source.write_bytes(first)
                before = consumer(staged)
                source.write_bytes(second)
                self.assertNotEqual(before, consumer(staged))
                with model.parsed_operation(self.root):
                    consumer(self.root)
                    source.write_bytes(first)
                    before = consumer(staged)
                    source.write_bytes(second)
                    self.assertNotEqual(before, consumer(staged))


if __name__ == "__main__":
    unittest.main()
