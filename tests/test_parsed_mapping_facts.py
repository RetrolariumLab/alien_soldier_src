"""Tiny genuine mapping-input facts, not models, pointer evidence or native PASS."""

from copy import deepcopy
import os
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import guarded_inventory as inventory
from authoring import sprite_mapping_model as sprites
from authoring import stage_tilemap_model as source


class ParsedMappingFactsTests(unittest.TestCase):
    def setUp(self):
        parent = ROOT / "build/test-fixtures/parsed-mapping-facts"
        parent.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix="owner-", dir=parent)
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.root = self.base / "root"
        self.write_tree(self.root)

    @staticmethod
    def write_tree(root, x=-1):
        for relative in ("src/empty", "data/empty", "config"):
            (root / relative).mkdir(parents=True, exist_ok=True)
        (root / "src/a.s").write_bytes(
            b"PairSpriteMapping: dc.w $0001,$0500,$FE08,$8002,$0000,$0203\r\n"
            b"SeriesSpriteMapping: dc.w $8003,$0000,$0102,$8004,$0000,$0304\r\n"
            b"DynamicSpriteMapping: dc.w $8001\r\n dc.l Art+$05000010\r\n dc.w $F608\r\n"
            b'PayloadSpriteMapping: binclude "data/sprites.bin"\r\n'
            b"PointerSpriteMapping: dc.l PairSpriteMapping,DynamicSpriteMapping\r\n"
            b"BadSpriteMapping: dc.w $8000,$0000\r\n"
            b"Terrain_StampObjectSpriteMapping: dc.w 0,0\r\n"
            b"MixedSpriteMapping: dc.w 0\r\n dc.b 0\r\n"
            b"Unrelated: dc.b 99\r\n"
        )
        (root / "src/z.s").write_bytes(b"ByteSpriteMapping: dc.b $80,$05,$00,$00,-1,2\r")
        (root / "data/sprites.bin").write_bytes(struct.pack(">HBBbb", 0x8003, 0, 0, 1, x))
        (root / "config/marker.json").write_bytes(b'{"outside_mapping_input":true}\n')

    @staticmethod
    def legacy(root):
        return sprites._parse_read_blocks(root)

    def rewrite_same_size(self, path):
        before, body = path.stat(), path.read_bytes()
        path.write_bytes(bytes([body[0] ^ 1]) + body[1:])
        os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
        self.assertEqual(before.st_size, path.stat().st_size)
        self.assertEqual(before.st_mtime_ns, path.stat().st_mtime_ns)
        return before, body

    @staticmethod
    def restore(path, before, body):
        path.write_bytes(body)
        os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))

    def test_static_dynamic_payload_skipped_newlines_and_concrete_types_match_fresh_parser(self):
        expected = self.legacy(self.root)
        with mock.patch.object(sprites, "_parse_read_blocks", wraps=sprites._parse_read_blocks) as parse:
            with source.parsed_operation(self.root) as operation:
                for _repeat in range(3):
                    actual = sprites.read_blocks(self.root)
                    self.assertEqual(expected, actual)
                    self.assertEqual(list(expected[1]), list(actual[1]))
                    self.assertIs(type(actual[0]), list)
                    self.assertIs(type(actual[1]), dict)
                    for block in actual[0]:
                        self.assertIs(type(block), sprites.MappingBlock)
                        self.assertIs(type(block.data), bytes)
                        self.assertIs(type(block.mappings), tuple)
                        for mapping in block.mappings:
                            self.assertIs(type(mapping), sprites.SpriteMapping)
                            self.assertIs(type(mapping.pieces), tuple)
                            self.assertTrue(all(type(piece) is sprites.SpritePiece for piece in mapping.pieces))
                self.assertEqual(1, parse.call_count)
                self.assertIs(type(operation._mapping_blocks), tuple)
        blocks = {block.name: block for block in expected[0]}
        self.assertEqual({"words", "bytes", "payload", "dynamic"}, {block.storage for block in blocks.values()})
        self.assertEqual((0, 6), tuple(mapping.offset for mapping in blocks["SeriesSpriteMapping"].mappings))
        piece = blocks["DynamicSpriteMapping"].mappings[0].pieces[0]
        self.assertEqual(("Art", 5, 0x10, -10, 8), (piece.art, piece.size, piece.art_addend, piece.y, piece.x))

    def test_blocks_mappings_pieces_and_all_mutable_returns_are_independent(self):
        expected = deepcopy(self.legacy(self.root))
        with source.parsed_operation(self.root):
            first, second = sprites.read_blocks(self.root), sprites.read_blocks(self.root)
            self.assertIsNot(first[0], second[0])
            self.assertIsNot(first[1], second[1])
            for left, right in zip(first[0], second[0], strict=True):
                self.assertIsNot(left, right)
                self.assertIsNot(left.mappings, right.mappings)
                for before, after in zip(left.mappings, right.mappings, strict=True):
                    self.assertIsNot(before, after)
                    self.assertIsNot(before.pieces, after.pieces)
                    for one, two in zip(before.pieces, after.pieces, strict=True):
                        self.assertIsNot(one, two)
                        object.__setattr__(one, "x", 999)
                    before.block, before.offset, before.pieces = "forged", -1, ()
                left.name, left.source, left.storage, left.payload, left.data, left.mappings = (
                    "forged",
                    "foreign",
                    "fake",
                    "none",
                    b"bad",
                    (),
                )
            first[0].clear()
            first[1].clear()
            self.assertEqual(expected, second)
            self.assertEqual(expected, sprites.read_blocks(self.root))

    def test_same_size_source_and_payload_rewrites_with_restored_mtime_fail_final_original_close(self):
        for relative in ("src/a.s", "data/sprites.bin"):
            path = self.root / relative
            before, body = path.stat(), path.read_bytes()
            try:
                with self.subTest(relative=relative), self.assertRaises(ValueError):
                    with source.parsed_operation(self.root):
                        sprites.read_blocks(self.root)
                        self.rewrite_same_size(path)
            finally:
                self.restore(path, before, body)
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_payload_drift_before_first_mapping_parse_is_not_swallowed_as_skipped(self):
        path = self.root / "data/sprites.bin"
        before, body = path.stat(), path.read_bytes()
        expected = self.legacy(self.root)
        with source.parsed_operation(self.root) as operation:
            operation.texts()  # Freeze both complete ORIGINAL owners before the mutation.
            try:
                self.rewrite_same_size(path)
                with self.assertRaisesRegex(ValueError, "ORIGINAL"):
                    sprites.read_blocks(self.root)
                self.assertIsNone(operation._mapping_blocks)
            finally:
                self.restore(path, before, body)
            self.assertEqual(expected, sprites.read_blocks(self.root))

    def test_added_empty_directory_or_new_source_fails_original_census(self):
        for relative, directory in (("src/late-empty", True), ("src/late.s", False)):
            path = self.root / relative
            try:
                with self.subTest(relative=relative), self.assertRaisesRegex(ValueError, "inventory"):
                    with source.parsed_operation(self.root):
                        sprites.read_blocks(self.root)
                        if directory:
                            path.mkdir()
                        else:
                            path.write_bytes(b"LateSpriteMapping: dc.w $8000,0,0\n")
            finally:
                if path.exists():
                    path.rmdir() if directory else path.unlink()
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_outside_payload_uses_fresh_fallback_without_caching_partial_original_results(self):
        assembly = self.root / "src/a.s"
        original = assembly.read_bytes()
        for relative in ("external.bin", "../outside.bin"):
            path = self.root / relative
            path.write_bytes(struct.pack(">HBBbb", 0x8003, 0, 0, 1, 2))
            assembly.write_bytes(original + ('ExternalSpriteMapping: binclude "%s"\n' % relative).encode())
            with self.subTest(relative=relative), source.parsed_operation(self.root) as operation:
                first = sprites.read_blocks(self.root)
                self.assertEqual(self.legacy(self.root), first)
                self.assertIsNone(operation._mapping_blocks)
                self.assertTrue(operation._mapping_unsupported)
                path.write_bytes(struct.pack(">HBBbb", 0x8003, 0, 0, 1, 3))
                second = sprites.read_blocks(self.root)
                self.assertEqual(self.legacy(self.root), second)
                self.assertNotEqual(first, second)
            assembly.write_bytes(original)

    def test_foreign_unlisted_and_outside_operation_roots_keep_the_fresh_parser(self):
        foreign = self.base / "foreign"
        self.write_tree(foreign, 2)
        with source.parsed_operation(self.root) as operation:
            for sentinel in (None, object()):

                def outcome(function):
                    try:
                        function(sentinel)
                    except Exception as error:
                        return type(error), str(error)
                    self.fail("malformed root unexpectedly produced mapping facts")

                self.assertEqual(outcome(self.legacy), outcome(sprites.read_blocks))
            self.assertEqual((), operation._owners)
            original = sprites.read_blocks(self.root)
            first = sprites.read_blocks(foreign)
            (foreign / "data/sprites.bin").write_bytes(struct.pack(">HBBbb", 0x8003, 0, 0, 1, 3))
            self.assertNotEqual(first, sprites.read_blocks(foreign))
            self.assertEqual(original, sprites.read_blocks(self.root))
        first = sprites.read_blocks(self.root)
        (self.root / "data/sprites.bin").write_bytes(struct.pack(">HBBbb", 0x8003, 0, 0, 1, 4))
        self.assertNotEqual(first, sprites.read_blocks(self.root))

    def test_pid_scope_lifetime_and_body_exception_refuse_reuse_and_restore_context(self):
        with source.parsed_operation(self.root) as operation:
            expected = sprites.read_blocks(self.root)
            with source.parsed_operation(self.root) as nested:
                self.assertIs(operation, nested)
                self.assertEqual(expected, sprites.read_blocks(self.root))
            with mock.patch.object(source.os, "getpid", return_value=os.getpid() + 1):
                with self.assertRaisesRegex(ValueError, "owning scope"):
                    operation.mapping_blocks()
            self.assertEqual(expected, sprites.read_blocks(self.root))
        self.assertIsNone(source._PARSED_OPERATION.get())
        with self.assertRaisesRegex(ValueError, "closed"):
            operation.mapping_blocks()
        with self.assertRaisesRegex(RuntimeError, "explicit body failure"):
            with source.parsed_operation(self.root) as failed:
                sprites.read_blocks(self.root)
                raise RuntimeError("explicit body failure")
        self.assertTrue(failed.closed)
        self.assertIsNone(source._PARSED_OPERATION.get())

    def readonly_trees(self):
        owner = self.root / "build/content/jp/source-format-builds/batch-jp-fixture"
        trees = {name: owner / name / "tree" for name in ("baseline", "edited")}
        for index, tree in enumerate(trees.values(), start=3):
            self.write_tree(tree, index)
        frozen = inventory.capture(owner, max_file=1 << 20, max_total=1 << 20, max_entries=1000)
        return owner, trees, frozen

    def test_readonly_staged_mapping_facts_use_only_explicit_original_src_data_authority(self):
        owner, trees, frozen = self.readonly_trees()
        expected = {name: self.legacy(tree) for name, tree in trees.items()}
        with source.parsed_operation(self.root) as primary:
            with source._readonly_staged_facts(self.root, owner, frozen, ("baseline", "edited")):
                first = sprites.read_blocks(trees["baseline"])
                child = source._read_operation(trees["baseline"])
                self.assertEqual((), primary._owners)  # Staged-first never recaptures primary.
                self.assertEqual(expected["baseline"], first)
                self.assertEqual(expected["edited"], sprites.read_blocks(trees["edited"]))
                self.assertEqual(expected["baseline"], sprites.read_blocks(trees["baseline"]))
                first[0][0].name = "forged returned stage"
                self.assertEqual(expected["baseline"], sprites.read_blocks(trees["baseline"]))
                # The readonly parse grant covers src/data, not metadata/config.
                (trees["baseline"] / "config/marker.json").write_bytes(b'{"not_a_mapping_input":true}\n')
            self.assertTrue(child.closed)
            self.assertIsNone(child._mapping_blocks)
            with self.assertRaisesRegex(ValueError, "closed"):
                child.mapping_blocks()
            self.assertEqual(expected["baseline"], sprites.read_blocks(trees["baseline"]))

    def test_staged_originals_close_after_readonly_scope_and_later_callback(self):
        owner, trees, frozen = self.readonly_trees()
        path = trees["edited"] / "data/sprites.bin"
        before, body = path.stat(), path.read_bytes()
        try:
            with self.assertRaises(ValueError):
                with source.parsed_operation(self.root):
                    with source._readonly_staged_facts(self.root, owner, frozen, ("baseline", "edited")):
                        sprites.read_blocks(trees["edited"])
                    self.rewrite_same_size(path)  # After final readonly callback, before true outer close.
        finally:
            self.restore(path, before, body)
        self.assertIsNone(source._PARSED_OPERATION.get())


if __name__ == "__main__":
    unittest.main()
