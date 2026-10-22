"""Small physical asset/descriptor fact controls; no ROM, SDK, AS or native."""

from collections import UserDict
from dataclasses import FrozenInstanceError
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import stage_tilemap_model as model


def legacy_asset_lists(bodies):
    found = {}
    for name, lines in bodies.items():
        commands = model.read_asset_list(name, lines)
        if commands:
            found[name] = tuple(commands)
    return found


def legacy_descriptors(root):
    found = {}
    for path in sorted(root.joinpath(model.SOURCE_ROOT).rglob("*.s")):
        for line in path.read_text(encoding="utf-8").split("\n"):
            match = model.DESCRIPTOR.match(line)
            if match is None or "VRAMTransferParameters" not in match.group("name"):
                continue
            values = [model.parse_number(token) for token in match.group("body").split(",")]
            if len(values) != 4:
                continue
            found[match.group("name")] = model.Descriptor(
                match.group("name"), values[0], values[1], values[2], bool(values[3] >> 16), values[3] & 0xFFFF
            )
    return found


class ParsedAssetFactsTests(unittest.TestCase):
    def setUp(self):
        base = ROOT / "build/test-fixtures/parsed-asset-facts"
        base.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix="owner-", dir=base)
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.source = self.write(
            "src/first.s",
            b"AssetsA:\n dc.w 6\n dc.l Blob\n"
            b' dc.w $4000\n dc.w $FFFF\nBlob: binclude "data/blob.bin"\n'
            b"Gfx_FixtureVRAMTransferParameters: dc.l $FFFF7000,$FFFF6000,$FFFF4000,$4000\n"
            b"Ignored: dc.b 1\nInvalidAssets: dc.w $FFFF\n",
        )
        self.last = self.write(
            "src/nested/last.s",
            b"AssetsB:\n dc.w 7\n dc.l Blob\n"
            b" dc.w 0\n dc.w -1\n"
            b"Gfx_OtherVRAMTransferParameters: dc.l $FFFF7100,$FFFF6100,$FFFF4100,$14000\n"
            b"Gfx_FixtureVRAMTransferParameters: dc.l $FFFF7200,$FFFF6200,$FFFF4200,$16000\n",
        )
        self.payload = self.write("data/blob.bin", b"\x12\x34\x56")
        (self.root / "src/empty").mkdir()
        (self.root / "data/empty").mkdir()

    def write(self, relative, body):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(body)
        return path

    @staticmethod
    def asset_lines(destination):
        return (" dc.w 6", " dc.l Blob", " dc.w $%X" % destination, " dc.w $FFFF")

    def change_same_size(self, path):
        before, body = path.stat(), path.read_bytes()
        path.write_bytes(bytes([body[0] ^ 1]) + body[1:])
        os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
        self.assertEqual(before.st_size, path.stat().st_size)
        self.assertEqual(before.st_mtime_ns, path.stat().st_mtime_ns)

    def test_canonical_asset_lists_parse_once_and_return_new_dicts_with_frozen_commands(self):
        with model.parsed_operation(self.root) as operation:
            _, bodies = model.labelled_blocks(self.root)
            expected = legacy_asset_lists(bodies)
            with mock.patch.object(model, "read_asset_list", wraps=model.read_asset_list) as parse:
                first = model.read_asset_lists(self.root, bodies)
                first.pop("AssetsA")
                second = model.read_asset_lists(self.root)
                self.assertEqual(len(bodies), parse.call_count)
            self.assertEqual(expected, second)
            self.assertEqual(list(expected), list(second))
            self.assertIsNot(first, second)
            self.assertIs(type(operation._asset_lists), tuple)
            self.assertIs(type(second["AssetsA"]), tuple)
            with self.assertRaises(FrozenInstanceError):
                second["AssetsA"][0].command = 2

    def test_custom_supplied_bodies_without_original_facts_never_capture_or_read_files(self):
        bodies = {"Custom": self.asset_lines(0x4020)}
        expected = legacy_asset_lists(bodies)
        with (
            mock.patch.object(model.guarded_inventory, "capture", side_effect=AssertionError("capture forbidden")),
            mock.patch.object(Path, "open", side_effect=AssertionError("file read forbidden")),
        ):
            for root in (self.root, object()):
                with self.subTest(root=type(root).__name__), model.parsed_operation(root) as operation:
                    self.assertEqual(expected, model.read_asset_lists(root, bodies))
                    self.assertIsNone(operation._facts)
                    self.assertIsNone(operation._asset_lists)

    def test_modified_reordered_copied_or_custom_bodies_keep_the_legacy_parser(self):
        with model.parsed_operation(self.root):
            _, bodies = model.labelled_blocks(self.root)
            model.read_asset_lists(self.root, bodies)
            changed = dict(bodies)
            changed["AssetsA"] = self.asset_lines(0x4020)
            copied = {name: tuple(list(lines)) for name, lines in bodies.items()}
            reordered = dict(reversed(tuple(bodies.items())))
            custom = UserDict(bodies)
            for candidate in (changed, copied, reordered, custom):
                expected = legacy_asset_lists(candidate)
                with (
                    self.subTest(kind=type(candidate).__name__),
                    mock.patch.object(model, "_parse_asset_lists", wraps=model._parse_asset_lists) as parse,
                ):
                    actual = model.read_asset_lists(self.root, candidate)
                    self.assertEqual(expected, actual)
                    self.assertEqual(list(expected), list(actual))
                    self.assertEqual(1, parse.call_count)

    def test_first_parse_callback_value_mutation_preserves_legacy_result_without_caching(self):
        with model.parsed_operation(self.root) as operation:
            _, bodies = model.labelled_blocks(self.root)
            real = model.read_asset_list

            def mutate(name, lines):
                commands = real(name, lines)
                if name == "AssetsB":
                    bodies["AssetsA"] = self.asset_lines(0x4020)
                return commands

            with mock.patch.object(model, "read_asset_list", side_effect=mutate):
                actual = model.read_asset_lists(self.root, bodies)
            self.assertEqual(0x4000, actual["AssetsA"][0].destination)
            self.assertIsNone(operation._asset_lists)
            self.assertEqual(0x4020, model.read_asset_lists(self.root, bodies)["AssetsA"][0].destination)

    def test_first_parse_callback_size_mutation_preserves_legacy_iteration_error(self):
        with model.parsed_operation(self.root) as operation:
            _, bodies = model.labelled_blocks(self.root)
            real = model.read_asset_list

            def mutate(name, lines):
                commands = real(name, lines)
                bodies["Late"] = self.asset_lines(0x4020)
                return commands

            with mock.patch.object(model, "read_asset_list", side_effect=mutate):
                with self.assertRaisesRegex(RuntimeError, "dictionary changed size"):
                    model.read_asset_lists(self.root, bodies)
            self.assertIsNone(operation._asset_lists)

    def test_descriptor_newlines_duplicates_and_mutable_returns_match_legacy(self):
        originals = tuple(path.read_bytes() for path in (self.source, self.last))
        for newline in (b"\n", b"\r\n", b"\r"):
            for path, body in zip((self.source, self.last), originals):
                path.write_bytes(body.replace(b"\n", newline))
            for root in (self.root, Path(os.path.relpath(self.root, Path.cwd()))):
                with self.subTest(newline=newline, root=root):
                    expected = legacy_descriptors(root)
                    with (
                        model.parsed_operation(root) as operation,
                        mock.patch.object(model, "_parse_descriptors", wraps=model._parse_descriptors) as parse,
                    ):
                        first = model.read_descriptors(root)
                        old_item = first["Gfx_FixtureVRAMTransferParameters"]
                        old_item.coarse = 17
                        first.clear()
                        second = model.read_descriptors(root)
                        self.assertEqual(1, parse.call_count)
                        self.assertIs(type(operation._descriptors), tuple)
                        self.assertTrue(all(type(row) is tuple for row in operation._descriptors))
                        self.assertEqual(expected, second)
                        self.assertEqual(list(expected), list(second))
                        self.assertIsNot(old_item, second["Gfx_FixtureVRAMTransferParameters"])
                        self.assertEqual(0xFFFF7200, second["Gfx_FixtureVRAMTransferParameters"].coarse)
                        self.assertIs(True, second["Gfx_FixtureVRAMTransferParameters"].mirror_to_plane_buffer)

    def test_descriptor_invalid_literal_keeps_the_original_error_and_no_fact_cache(self):
        self.source.write_bytes(self.source.read_bytes() + b"Gfx_InvalidVRAMTransferParameters: dc.l nope,2,3,4\n")
        with self.assertRaises(ValueError) as original:
            legacy_descriptors(self.root)
        with model.parsed_operation(self.root) as operation:
            with self.assertRaises(ValueError) as actual:
                model.read_descriptors(self.root)
            self.assertEqual(str(original.exception), str(actual.exception))
            self.assertIsNone(operation._descriptors)

    def test_external_include_unsupported_operation_keeps_both_facts_fresh(self):
        self.write("external/blob.bin", b"external")
        self.write("src/external.s", b'External: binclude "external/blob.bin"\n')
        with model.parsed_operation(self.root) as operation:
            model.labelled_blocks(self.root)
            self.assertTrue(operation._unsupported)
            with (
                mock.patch.object(model, "_parse_asset_lists", wraps=model._parse_asset_lists) as assets,
                mock.patch.object(model, "_parse_descriptors", wraps=model._parse_descriptors) as descriptors,
            ):
                for _ in range(2):
                    self.assertEqual(
                        legacy_asset_lists(model.labelled_blocks(self.root)[1]), model.read_asset_lists(self.root)
                    )
                    self.assertEqual(legacy_descriptors(self.root), model.read_descriptors(self.root))
                self.assertEqual(2, assets.call_count)
                self.assertEqual(2, descriptors.call_count)
            self.assertIsNone(operation._asset_lists)
            self.assertIsNone(operation._descriptors)

    def test_staged_roots_and_later_operations_do_not_reuse_either_fact(self):
        staged = self.root / "build/staged"
        (staged / "src").mkdir(parents=True)
        path = staged / "src/only.s"
        first = (
            b"Assets:\n dc.w 6\n dc.l Blob\n dc.w $4000\n dc.w $FFFF\nGfx_StagedVRAMTransferParameters: dc.l 1,2,3,4\n"
        )
        second = first.replace(b"$4000", b"$4002").replace(b"dc.l 1,2,3,4", b"dc.l 5,2,3,4")

        def facts(root):
            return model.read_asset_lists(root), model.read_descriptors(root)

        path.write_bytes(first)
        before = facts(staged)
        path.write_bytes(second)
        self.assertNotEqual(before, facts(staged))
        with model.parsed_operation(self.root) as operation:
            facts(self.root)
            path.write_bytes(first)
            before = facts(staged)
            path.write_bytes(second)
            self.assertNotEqual(before, facts(staged))
        with self.assertRaisesRegex(ValueError, "closed"):
            operation.asset_lists({})
        with self.assertRaisesRegex(ValueError, "closed"):
            operation.descriptors()
        with model.parsed_operation(self.root) as fresh:
            self.assertIsNone(fresh._asset_lists)
            self.assertIsNone(fresh._descriptors)
            facts(self.root)

    def test_either_first_reader_retains_original_raw_bytes_and_directory_census(self):
        for reader in (model.read_asset_lists, model.read_descriptors):
            for relative in ("src/first.s", "data/blob.bin", "src/late.s", "data/empty/late"):
                path = self.root / relative
                original = path.read_bytes() if path.is_file() else None
                with self.subTest(reader=reader.__name__, relative=relative):
                    with self.assertRaises(ValueError):
                        with model.parsed_operation(self.root):
                            reader(self.root)
                            if original is not None:
                                self.change_same_size(path)
                            elif relative.endswith(".s"):
                                path.write_bytes(b"Late: dc.b 7\n")
                            else:
                                path.mkdir()
                    if original is not None:
                        path.write_bytes(original)
                    elif path.is_dir():
                        path.rmdir()
                    else:
                        path.unlink()


if __name__ == "__main__":
    unittest.main()
