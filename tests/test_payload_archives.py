"""Pin compressed-payload boundaries independently of the repacker worktree."""

from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from unpack_data import unpack_data  # noqa: E402


PAIRS = (
    ("artcomp/tiles_104B22.bin", "artcomp/tiles_104F32.bin", 28),
    ("artcomp/tiles_105196.bin", "artcomp/tiles_105B9E.bin", 123),
    ("artcomp/tiles_121932.bin", "artcomp/tiles_123172.bin", 27),
    ("artcomp/tiles_12772E.bin", "artcomp/tiles_1291DE.bin", 303),
    ("artcomp/tiles_136512.bin", "artcomp/tiles_138EE4.bin", 75),
    ("artcomp/tiles_13C166.bin", "artcomp/tiles_13D42A.bin", 322),
    ("mappings/byte_1889B0.bin", "mappings/byte_188A16.bin", 194),
    ("mappings/byte_1BD048.bin", "mappings/byte_1BE2CA.bin", 44),
)
TAILS = (
    ("mappings/byte_1BE722.bin", 64),
    ("mappings/byte_19C492.bin", 18),
)


class PayloadArchiveTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.assets = {
            item["path"]: item
            for item in json.loads((ROOT / "assets/manifest.json").read_text(encoding="utf-8"))["assets"]
        }

    def test_eight_second_archives_have_exact_ranges_and_tile_counts(self) -> None:
        for first, second, tile_count in PAIRS:
            with self.subTest(second=second):
                start = self.assets[first]
                end = self.assets[second]
                self.assertEqual(int(start["end"], 16), int(end["address"], 16))
                self.assertEqual(int(end["end"], 16) - int(end["address"], 16), end["size"])
                for path in (first, second):
                    data_path = ROOT / "data" / path
                    if not data_path.is_file():
                        self.skipTest("private extracted assets are unavailable")
                    raw = data_path.read_bytes()
                    self.assertEqual(self.assets[path]["size"], len(raw))
                    body_size = int.from_bytes(raw[:2], "big")
                    self.assertEqual(len(raw), 2 + body_size + (body_size & 1))
                plain, error = unpack_data((ROOT / "data" / second).read_bytes())
                self.assertIsNone(error)
                self.assertEqual(tile_count * 32, len(plain))

    def test_artcomp_files_end_at_the_first_archive_boundary(self) -> None:
        paths = sorted(path for path in self.assets if path.startswith("artcomp/"))
        self.assertEqual(128, len(paths))
        for path in paths:
            with self.subTest(path=path):
                data_path = ROOT / "data" / path
                if not data_path.is_file():
                    self.skipTest("private extracted assets are unavailable")
                raw = data_path.read_bytes()
                body_size = int.from_bytes(raw[:2], "big")
                self.assertEqual(len(raw), 2 + body_size + (body_size & 1))

    def test_nonarchive_tails_are_separate_and_role_neutral(self) -> None:
        for path, size in TAILS:
            with self.subTest(path=path):
                self.assertEqual(size, self.assets[path]["size"])
                data_path = ROOT / "data" / path
                if not data_path.is_file():
                    self.skipTest("private extracted assets are unavailable")
                raw = data_path.read_bytes()
                self.assertEqual(size, len(raw))
                self.assertGreater(int.from_bytes(raw[:2], "big"), size - 2)
                if size == 18:
                    self.assertEqual(3, len(raw) // 6)
                    self.assertEqual(
                        [False, False, True],
                        [bool(int.from_bytes(raw[index : index + 2], "big") & 0x8000) for index in (0, 6, 12)],
                    )

    def test_no_small_symbol_offset_reaches_inside_an_archive(self) -> None:
        sources = sorted((ROOT / "src").rglob("*.s"))
        binclude = re.compile(r'^([A-Za-z_]\w*):\s+binclude\s+"data/([^\"]+)"')
        archive_paths = {path for first, second, _ in PAIRS for path in (first, second)}
        payload_symbols = set()
        for path in sources:
            for line in path.read_text(encoding="utf-8").splitlines():
                if (match := binclude.match(line)) and (
                    match.group(2).startswith("artcomp/") or match.group(2) in archive_paths
                ):
                    payload_symbols.add(match.group(1))
                    payload_symbols.add(match.group(1) + "_End")
        reference = re.compile(r"\b([A-Za-z_]\w*)\+\$([0-9A-Fa-f]+)\b")
        interior = []
        for path in sources:
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                for match in reference.finditer(line.split(";", 1)[0]):
                    if match.group(1) in payload_symbols and int(match.group(2), 16) < 0x10000:
                        interior.append((path.relative_to(ROOT).as_posix(), line_number))
        self.assertEqual([], interior)

    def test_three_former_interior_pointers_name_second_archives(self) -> None:
        source = (ROOT / "src/stages/visual_asset_loading.s").read_text(encoding="utf-8")
        for command, symbol in (
            ("Stage7TileAssetCommands", "Stage15TileArt2"),
            ("Stage16TileAssetCommands", "Boss_BackStringerTileArt2"),
            ("Stage18TileAssetCommands", "Stage22And24TileArt2"),
        ):
            with self.subTest(command=command):
                body = source.split(command + ":", 1)[1].split("$FFFF", 1)[0]
                self.assertIn(f"dc.l    {symbol}", body)


if __name__ == "__main__":
    unittest.main()
