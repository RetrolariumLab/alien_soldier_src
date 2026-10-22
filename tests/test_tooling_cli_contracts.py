"""The public command-line tools start and show their help without a ROM."""

from contextlib import redirect_stdout
import io
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import check_init
import validate_movie_descriptions as descriptions


class ToolingCLIContracts(unittest.TestCase):
    def test_compatible_public_clis_show_help_without_rom_workspace_or_runtime(self):
        entries = (
            "scripts/authoring/check_tile_codec_rom.py",
            "scripts/authoring/palettes.py",
            "scripts/authoring/sprite_mappings.py",
            "scripts/authoring/stage_tilemaps.py",
            "scripts/authoring/tile_art.py",
            "scripts/bintrace_parser.py",
            "scripts/compare_states.py",
            "scripts/compare_traces.py",
            "scripts/extract_data_addrs.py",
            "scripts/find_unnamed_procedures.py",
            "scripts/generate_analysis_report.py",
            "scripts/generate_asset_manifest.py",
            "scripts/inspect_runtime_ram.py",
            "scripts/rename_procedures.py",
        )
        retired = {
            "scripts/find_unnamed_procedures.py": "retired monolithic",
            "scripts/rename_procedures.py": "is retired",
        }
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            for relative in entries:
                with self.subTest(entry=relative):
                    result = subprocess.run(
                        [sys.executable, "-B", str(ROOT / relative), "--help"],
                        cwd=directory,
                        capture_output=True,
                        text=True,
                        timeout=10,
                    )
                    self.assertEqual(1 if relative in retired else 0, result.returncode, result.stdout + result.stderr)
                    if relative in retired:
                        self.assertIn(retired[relative], result.stdout + result.stderr)
                    else:
                        self.assertIn("usage:", result.stdout.lower())
                    self.assertEqual([], list(directory.iterdir()))

    def test_check_init_reports_missing_directories_and_accepts_only_ready_tree(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            args = ["check_init", "--data-dir", str(root / "data"), "--orig-rom", "private-original"]
            with mock.patch.object(sys, "argv", args), redirect_stdout(io.StringIO()) as output:
                self.assertEqual(1, check_init.main())
            self.assertIn("make init", output.getvalue())
            for directory in check_init.REQUIRED_DATA_DIRS:
                (root / "data" / directory).mkdir(parents=True)
            with mock.patch.object(sys, "argv", args), redirect_stdout(io.StringIO()):
                self.assertEqual(0, check_init.main())

    def test_movie_description_intervals_reject_overlap_gap_and_bad_start(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "description.txt"
            for text, expected in (
                ("20-100, boot\n120-200, attract\n", True),
                ("0-100, boot\n120-200, attract\n", False),
                ("20-100, boot\n90-200, overlap\n", False),
                ("20-100, boot\n140-200, gap\n", False),
            ):
                path.write_text("Frames, Scene\n" + text, encoding="utf-8")
                with self.subTest(text=text), redirect_stdout(io.StringIO()):
                    self.assertEqual(expected, descriptions.validate_description_file(path))


if __name__ == "__main__":
    unittest.main()
