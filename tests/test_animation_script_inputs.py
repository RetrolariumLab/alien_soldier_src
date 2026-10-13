"""Symbol-preserving animation parser inputs and ORIGINAL scope guards."""

import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import guarded_inventory as inventory
from authoring import object_sprite_model as sprites
from authoring import stage_tilemap_model as model


def legacy_animation_scripts(root):
    """Frozen original algorithm; independent of the proposed parser/helper."""
    scripts = {}
    for path in sorted(root.joinpath(sprites.SOURCE_ROOT).rglob("*.s")):
        name = None
        kind = None
        tokens = []

        def flush():
            if not (name and tokens and kind == "dc.w" and len(tokens) % 2 == 0):
                return
            frames = []
            for at in range(0, len(tokens), 2):
                head = sprites.RELATIVE_FRAME.match(tokens[at])
                if head is None:
                    return
                try:
                    duration = sprites.parse_number(tokens[at + 1])
                except ValueError:
                    return
                frames.append(sprites.Frame(head.group(1), duration))
            if frames:
                scripts[name] = tuple(frames)

        for line in path.read_text(encoding="utf-8").split("\n"):
            head = sprites.LABEL_LINE.match(line)
            if head:
                flush()
                name, kind, tokens = head.group("name"), None, []
                line = head.group("rest")
            directive = sprites.DIRECTIVE.match(line)
            if directive is None or name is None:
                continue
            if kind is None:
                kind = directive.group("kind")
            elif kind != directive.group("kind"):
                continue
            tokens.extend(token.strip() for token in directive.group("body").split(","))
        flush()
    return scripts


class AnimationScriptInputsTests(unittest.TestCase):
    def setUp(self):
        base = ROOT / "build/test-fixtures/animation-script-inputs"
        base.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix="f", dir=base)
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.owner = self.root / "build/cases/fixed-owner"
        self.baseline = self.owner / "baseline/tree"
        self.edited = self.owner / "edited/tree"
        self.other = self.root / "build/unlisted/tree"
        for tree, duration in ((self.root, 4), (self.baseline, 5),
                               (self.edited, 6), (self.other, 7)):
            self.write_tree(tree, duration)
        self.source = self.root / "src/a.s"
        self.payload = self.root / "data/blob.bin"
        self.frozen = inventory.capture(self.owner, max_file=1 << 20,
                                       max_total=1 << 20, max_entries=1000)

    @staticmethod
    def write_tree(tree, duration):
        (tree / "src/nested").mkdir(parents=True, exist_ok=True)
        (tree / "src/empty").mkdir(exist_ok=True)
        (tree / "data/empty").mkdir(parents=True, exist_ok=True)
        (tree / "data/blob.bin").write_bytes(b"\x01\x02")
        (tree / "src/a.s").write_bytes((
            "Anim: dc.w Map-*,$%X ; comment\n dc.w Anim-*,0\n"
            "Duplicate: dc.w Old-*,1\n"
            "Odd: dc.w Map-*,1,Map-*\n"
            "BadTarget: dc.w $20,1\n"
            "BadDuration: dc.w Map-*,unknown\n"
            "WrongKind: dc.l Map-*,1\n dc.w Map-*,2\n"
            "Mixed: dc.w Map-*,3\n dc.b 7\n dc.w Other-*,4\n"
            "Duplicate: dc.w Local-*,2\n" % duration).encode())
        (tree / "src/nested/z.s").write_bytes(
            b"Duplicate: dc.w Last-*,3\nTail: dc.w Final-*,-1\n")

    def scope(self):
        return model._readonly_staged_facts(self.root, self.owner,
                                           self.frozen, ("baseline", "edited"))

    def change_same_size(self, path):
        before, body = path.stat(), path.read_bytes()
        path.write_bytes(bytes([body[0] ^ 1]) + body[1:])
        os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
        self.assertEqual(before.st_size, path.stat().st_size)
        self.assertEqual(before.st_mtime_ns, path.stat().st_mtime_ns)

    def test_original_parser_parity_order_newlines_duplicates_and_invalid_pairs(self):
        original = self.source.read_bytes()
        for newline in (b"\n", b"\r\n", b"\r"):
            with self.subTest(newline=newline):
                self.source.write_bytes(original.replace(b"\n", newline))
                expected = legacy_animation_scripts(self.root)
                self.assertEqual(expected, sprites.read_animation_scripts(self.root))
                with model.parsed_operation(self.root):
                    actual = sprites.read_animation_scripts(self.root)
                    self.assertEqual(expected, actual)
                    self.assertEqual(list(expected), list(actual))
                self.assertEqual((sprites.Frame("Last", 3),), actual["Duplicate"])
                self.assertEqual((sprites.Frame("Map", 3), sprites.Frame("Other", 4)), actual["Mixed"])
                self.assertTrue(actual["Anim"][1].is_jump)
                for invalid in ("Odd", "BadTarget", "BadDuration", "WrongKind"):
                    self.assertNotIn(invalid, actual)

    def test_one_scope_parses_once_and_all_public_containers_and_frames_are_fresh(self):
        expected = legacy_animation_scripts(self.root)
        with mock.patch.object(sprites, "_parse_animation_scripts",
                               wraps=sprites._parse_animation_scripts) as parse:
            with model.parsed_operation(self.root):
                first = sprites.read_animation_scripts(self.root)
                second = sprites.read_animation_scripts(self.root)
                self.assertIsNot(first, second)
                self.assertIsNot(first["Anim"], second["Anim"])
                self.assertIsNot(first["Anim"][0], second["Anim"][0])
                object.__setattr__(first["Anim"][0], "mapping", "Forged")
                object.__setattr__(first["Anim"][1], "duration", 99)
                first.clear()
                self.assertEqual(expected, second)
                self.assertEqual(expected, sprites.read_animation_scripts(self.root))
                self.assertEqual(1, parse.call_count)
            self.assertEqual(expected, sprites.read_animation_scripts(self.root))
            self.assertEqual(2, parse.call_count)

    def test_late_same_size_source_and_payload_changes_fail_original_final_close(self):
        for path in (self.source, self.payload):
            original = path.read_bytes()
            try:
                with self.subTest(path=path), self.assertRaisesRegex(ValueError, "raw file changed"):
                    with model.parsed_operation(self.root):
                        expected = sprites.read_animation_scripts(self.root)
                        self.change_same_size(path)
                        self.assertEqual(expected, sprites.read_animation_scripts(self.root))
            finally:
                path.write_bytes(original)
            self.assertIsNone(model._PARSED_OPERATION.get())

    def test_added_source_or_empty_directory_fails_original_final_census(self):
        for relative, body in (("src/late.s", b"Late: dc.w Map-*,1\n"),
                               ("data/empty/late", None)):
            path = self.root / relative
            try:
                with self.subTest(relative=relative), self.assertRaisesRegex(ValueError, "directory inventory changed"):
                    with model.parsed_operation(self.root):
                        sprites.read_animation_scripts(self.root)
                        path.mkdir() if body is None else path.write_bytes(body)
            finally:
                path.rmdir() if body is None else path.unlink()
            self.assertIsNone(model._PARSED_OPERATION.get())

    def test_only_registered_exact_readonly_roots_share_distinct_original_pairs(self):
        expected = {tree: legacy_animation_scripts(tree)
                    for tree in (self.root, self.baseline, self.edited)}
        with mock.patch.object(sprites, "_parse_animation_scripts",
                               wraps=sprites._parse_animation_scripts) as parse:
            with model.parsed_operation(self.root):
                with self.scope():
                    for tree in (self.baseline, self.edited, self.root, self.edited, self.baseline):
                        self.assertEqual(expected[tree], sprites.read_animation_scripts(tree))
                    self.assertEqual(3, parse.call_count)
                    first = sprites.read_animation_scripts(self.other)
                    other = self.other / "src/a.s"
                    other.write_bytes(other.read_bytes().replace(b"Map-*,$7", b"Map-*,$8"))
                    self.assertNotEqual(first, sprites.read_animation_scripts(self.other))
                    self.assertEqual(5, parse.call_count)
                # The SAME baseline path outside its explicit registry is fresh.
                path = self.baseline / "src/a.s"
                original = path.read_bytes()
                try:
                    path.write_bytes(original.replace(b"Map-*,$5", b"Map-*,$9"))
                    self.assertEqual(9, sprites.read_animation_scripts(self.baseline)["Anim"][0].duration)
                    self.assertEqual(6, parse.call_count)
                finally:
                    path.write_bytes(original)

    def test_readonly_exit_and_body_exception_end_capability_and_reset_scope(self):
        with model.parsed_operation(self.root) as primary:
            with self.scope():
                sprites.read_animation_scripts(self.baseline)
                child = primary._readonly["facts"][self.baseline]
                with mock.patch.object(model.os, "getpid", return_value=child.pid + 1):
                    with self.assertRaisesRegex(ValueError, "outside its owning scope"):
                        child.animation_scripts()
            self.assertIsNone(child._animation_scripts)
            with self.assertRaisesRegex(ValueError, "closed"):
                child.animation_scripts()
        with self.assertRaisesRegex(ValueError, "closed"):
            primary.animation_scripts()
        with self.assertRaisesRegex(RuntimeError, "fixture callback"):
            with model.parsed_operation(self.root):
                sprites.read_animation_scripts(self.root)
                raise RuntimeError("fixture callback")
        self.assertIsNone(model._PARSED_OPERATION.get())
        self.assertEqual(legacy_animation_scripts(self.root), sprites.read_animation_scripts(self.root))

    def test_physical_bytes_changed_between_original_census_and_parse_cannot_rebind(self):
        original = self.source.read_bytes()
        actual_capture = inventory.capture
        changed = False

        def capture_then_change(owner, **kwargs):
            nonlocal changed
            records = actual_capture(owner, **kwargs)
            if owner == self.root / "data" and not changed:
                changed = True
                self.change_same_size(self.source)
            return records

        try:
            with mock.patch.object(inventory, "capture", side_effect=capture_then_change):
                with self.assertRaisesRegex(ValueError, "ORIGINAL|raw file changed"):
                    with model.parsed_operation(self.root):
                        sprites.read_animation_scripts(self.root)
            self.assertTrue(changed)
        finally:
            self.source.write_bytes(original)
        self.assertIsNone(model._PARSED_OPERATION.get())


if __name__ == "__main__":
    unittest.main()
