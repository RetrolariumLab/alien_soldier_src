from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import analyze_procedures  # noqa: E402


class AnalyzeProceduresTests(unittest.TestCase):
    def test_resolves_named_procedures_in_rom_order(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src"
            source.mkdir()
            (source / "main.s").write_text(
                '                include "src/first.s"\n                include "src/second.s"\n',
                encoding="utf-8",
            )
            (source / "first.s").write_text(
                "First:\n                rts\n; End of function First\n",
                encoding="utf-8",
            )
            (source / "second.s").write_text(
                "Second:\n                rts\n; End of function Second\n",
                encoding="utf-8",
            )
            queue = root / "queue.txt"
            queue.write_text("Second\nFirst\n", encoding="utf-8")

            procedures = analyze_procedures.load_procedures_from_file(queue, source / "main.s")

            self.assertEqual(["First", "Second"], [item["name"] for item in procedures])
            self.assertEqual(["src/first.s", "src/second.s"], [item["module"] for item in procedures])
            self.assertEqual([0, 1], [item["order"] for item in procedures])

            analyze_procedures.disable_procedure(source / "second.s", "Second")
            self.assertIn("rts\t; DISABLED BY ANALYZER", (source / "second.s").read_text(encoding="utf-8"))

    def test_rejects_missing_definition_without_writing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            module = Path(directory) / "module.s"
            module.write_text("Other:\n                rts\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "found 0"):
                analyze_procedures.disable_procedure(module, "Absent")
            self.assertEqual("Other:\n                rts\n", module.read_text(encoding="utf-8"))

    def test_worker_mutation_stays_in_its_private_module_copy(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            project = root / "project"
            project.mkdir()
            (project / "Makefile").write_text("build:\n", encoding="utf-8")
            for name in ("bin", "data", "src", "scripts", "assets", "config"):
                (project / name).mkdir()
            module = project / "src" / "module.s"
            original = "Target:\n                rts\n"
            module.write_text(original, encoding="utf-8")
            workers = root / "workers"
            workers.mkdir()

            worker = Path(analyze_procedures.setup_worker_dir(project, "Target", workers))
            analyze_procedures.disable_procedure(worker / "src" / "module.s", "Target")

            self.assertEqual(original, module.read_text(encoding="utf-8"))
            self.assertIn(
                "DISABLED BY ANALYZER",
                (worker / "src" / "module.s").read_text(encoding="utf-8"),
            )
            self.assertTrue((worker / "config").is_dir())
            self.assertTrue((worker / "assets").is_dir())

    def test_failed_emulator_is_not_reported_as_no_change(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(
                analyze_procedures.subprocess,
                "run",
                return_value=SimpleNamespace(returncode=7, stderr=b"replay failed"),
            ):
                with self.assertRaisesRegex(RuntimeError, "replay failed"):
                    analyze_procedures.run_comparison(
                        "gens.exe", "rom.bin", "movie.gmv", "reference", directory, "Target"
                    )


if __name__ == "__main__":
    unittest.main()
