from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import find_review_procedures  # noqa: E402


class FindReviewProceduresTests(unittest.TestCase):
    def test_selects_delimited_hypotheses_in_include_order(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src"
            source.mkdir()
            (source / "main.s").write_text(
                '                include "src/second.s"\n                include "src/first.s"\n',
                encoding="utf-8",
            )
            (source / "second.s").write_text(
                "Second:\n                rts\n; End of function Second\n"
                "Static:\n                rts\n; End of function Static\n",
                encoding="utf-8",
            )
            (source / "first.s").write_text(
                "First:\n                rts\n; End of function First\nData: dc.l $1234\n",
                encoding="utf-8",
            )
            audit = root / "audit.json"
            audit.write_text(
                json.dumps(
                    {
                        "records": [
                            {"current_name": name, "evidence": evidence}
                            for name, evidence in (
                                ("First", "hypothesis"),
                                ("Second", "hypothesis"),
                                ("Static", "static"),
                                ("Data", "hypothesis"),
                            )
                        ]
                    }
                ),
                encoding="utf-8",
            )

            selected, missing = find_review_procedures.review_candidates(source / "main.s", audit)

            self.assertEqual(["Second", "First"], selected)
            self.assertEqual(["Data"], missing)

            payload = json.loads(audit.read_text(encoding="utf-8"))
            payload["records"].append({"current_name": "Ghost", "evidence": "hypothesis"})
            audit.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Ghost"):
                find_review_procedures.review_candidates(source / "main.s", audit)


if __name__ == "__main__":
    unittest.main()
