from __future__ import annotations

from contextlib import redirect_stdout
from io import StringIO
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import debug_pointers  # noqa: E402
import report_pointers  # noqa: E402


class RetiredPointerToolsTests(unittest.TestCase):
    def test_debugger_refuses_before_starting_a_worker(self) -> None:
        output = StringIO()
        with patch.object(debug_pointers, "setup_worker_dir", side_effect=AssertionError), redirect_stdout(output):
            self.assertEqual(1, debug_pointers.main())
        self.assertIn("make verify-relocation", output.getvalue())

    def test_report_refuses_before_cleanup(self) -> None:
        output = StringIO()
        with patch.object(report_pointers, "cleanup_empty_dirs", side_effect=AssertionError), redirect_stdout(output):
            self.assertEqual(1, report_pointers.main())
        self.assertIn("make verify-relocation", output.getvalue())


if __name__ == "__main__":
    unittest.main()
