from __future__ import annotations

from contextlib import redirect_stdout
from io import StringIO
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import split_data_from_listing  # noqa: E402


class RetiredAssetSplitterTests(unittest.TestCase):
    def test_refuses_before_writing_source_or_payloads(self) -> None:
        output = StringIO()
        with (
            patch.object(
                split_data_from_listing,
                "save_binary_files",
                side_effect=AssertionError("must not extract"),
            ),
            redirect_stdout(output),
        ):
            self.assertEqual(1, split_data_from_listing.main())
        self.assertIn("make split", output.getvalue())


if __name__ == "__main__":
    unittest.main()
