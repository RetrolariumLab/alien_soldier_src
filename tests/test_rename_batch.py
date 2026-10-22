from __future__ import annotations

from contextlib import redirect_stdout
from io import StringIO
import os
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import rename_batch  # noqa: E402


class RenameBatchTests(unittest.TestCase):
    def test_renames_across_modules_and_marks_report(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src"
            source.mkdir()
            module = source / "module.s"
            module.write_text("Old:  ; was: sub_1234\n                jsr Old\n", encoding="utf-8")
            workflow = root / "workflow"
            workflow.mkdir()
            (workflow / ".movie").write_text("tas\n", encoding="utf-8")
            (workflow / "rename_batch.csv").write_text(
                "old_name,new_name,description\nOld,New,reviewed\n", encoding="utf-8"
            )
            report = workflow / "analysis_report_tas.csv"
            report.write_text("procedure,processed\nOld,\n", encoding="utf-8")

            previous = Path.cwd()
            try:
                os.chdir(root)
                with redirect_stdout(StringIO()):
                    result = rename_batch.main([])
            finally:
                os.chdir(previous)

            self.assertEqual(0, result)
            self.assertEqual(
                "New:  ; was: sub_1234\n                jsr New\n",
                module.read_text(encoding="utf-8"),
            )
            self.assertEqual("procedure,processed\nOld,true\n", report.read_text(encoding="utf-8"))

    def test_rejects_unknown_movie_before_changing_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / ".movie"
            marker.write_text("other\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "unknown movie"):
                rename_batch.report_for_movie(marker)


if __name__ == "__main__":
    unittest.main()
