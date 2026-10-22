from __future__ import annotations

from contextlib import redirect_stdout
from io import StringIO
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import prepare_batch  # noqa: E402


class PrepareBatchTests(unittest.TestCase):
    def test_finds_procedure_in_include_order(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src"
            source.mkdir()
            (source / "main.s").write_text(
                '                include "src/first.s"\n                include "src/second.s"\n',
                encoding="utf-8",
            )
            (source / "first.s").write_text("First:\n                rts\n", encoding="utf-8")
            (source / "second.s").write_text("Target:\n                rts\n", encoding="utf-8")

            modules = prepare_batch.source_modules(source / "main.s")
            self.assertEqual([source / "first.s", source / "second.s"], modules)
            output = prepare_batch.extract_procedure_code("Target", source / "main.s")
            self.assertIn(f"Source module: {source / 'second.s'}", output)
            self.assertIn("Target:\n                rts", output)
            self.assertIn("Boundary: no matching End of function marker", output)
            self.assertIn("not found", prepare_batch.extract_procedure_code("Absent", source / "main.s"))

    def test_long_procedure_reaches_its_named_end_marker(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            module = Path(directory) / "long.s"
            module.write_text(
                "Target:\n"
                + "; End of function TargetExtra\n"
                + "                nop\n" * 550
                + "; End of function Target\n"
                + "Other:\n                rts\n",
                encoding="utf-8",
            )

            output = prepare_batch.extract_procedure_code("Target", module)
            self.assertEqual(550, output.count("                nop"))
            self.assertIn("; End of function Target", output)
            self.assertNotIn("Boundary: no matching", output)

    def test_missing_included_module_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "src"
            source.mkdir()
            (source / "main.s").write_text('                include "src/missing.s"\n', encoding="utf-8")
            with self.assertRaises(FileNotFoundError):
                prepare_batch.source_modules(source / "main.s")

    def test_cli_selects_report_from_movie_marker(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src"
            source.mkdir()
            (source / "main.s").write_text('                include "src/module.s"\n', encoding="utf-8")
            (source / "module.s").write_text(
                "Target:\n                rts\n; End of function Target\n",
                encoding="utf-8",
            )
            workflow = root / "workflow"
            workflow.mkdir()
            marker = workflow / ".movie"
            marker.write_text("tas\n", encoding="utf-8")
            (workflow / "analysis_report_tas.csv").write_text("procedure,address\nTarget,1234\n", encoding="utf-8")
            output = workflow / "batch.txt"

            with redirect_stdout(StringIO()):
                result = prepare_batch.main(
                    ["--movie-file", str(marker), "--source", str(source / "main.s"), "--output", str(output)]
                )

            self.assertEqual(0, result)
            self.assertIn("Source module:", output.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
