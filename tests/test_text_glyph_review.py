from __future__ import annotations

import hashlib
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.text_glyph_review import (  # noqa: E402
    inventory,
    render_html,
    validate_answers,
    write_page,
)


class TextGlyphReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.assets = inventory(ROOT)

    def test_three_review_sets_pin_two_fonts_and_credits_usage(self) -> None:
        self.assertEqual(
            {"shared": (0, 228), "japanese": (0x20, 295), "credits": (0, 228)},
            {name: (asset["first"], asset["count"]) for name, asset in self.assets.items()},
        )
        for asset in self.assets.values():
            self.assertRegex(asset["sha256"], r"^[0-9a-f]{64}$")
        self.assertEqual(
            hashlib.sha256((ROOT / "data/artunc/font.bin").read_bytes()).hexdigest(),
            self.assets["shared"]["sha256"],
        )
        self.assertEqual(self.assets["shared"]["sha256"], self.assets["credits"]["sha256"])

    def test_page_embeds_exact_inventory_without_character_claims(self) -> None:
        page = render_html(ROOT)
        match = re.search(r"const assets = (\{[^;]+\});", page)
        self.assertIsNotNone(match)
        self.assertEqual(self.assets, json.loads(match.group(1)))
        self.assertNotIn("__GLYPH_DATA__", page)
        self.assertIn("source order", page)
        self.assertIn("Unknown / possibly unused", page)
        self.assertIn("source_hashes", page)
        self.assertIn("choose an evidence level before exporting", page)

    def test_existing_local_review_is_not_overwritten_without_force(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            page = Path(temporary) / "review.html"
            write_page(page, "first", force=False)
            with self.assertRaisesRegex(ValueError, "already exists"):
                write_page(page, "second", force=False)
            self.assertEqual("first", page.read_text(encoding="utf-8"))
            write_page(page, "second", force=True)
            self.assertEqual("second", page.read_text(encoding="utf-8"))

    def test_returned_answers_are_bound_to_source_and_evidence(self) -> None:
        document = {
            "schema_version": 1,
            "source_hashes": {name: asset["sha256"] for name, asset in self.assets.items()},
            "answers": [
                {
                    "set": "shared",
                    "index": 0,
                    "transcription": "A",
                    "evidence": "in_game",
                    "notes": "frame 123",
                }
            ],
        }
        self.assertEqual(1, validate_answers(document, self.assets))
        duplicate = dict(document, answers=document["answers"] * 2)
        with self.assertRaisesRegex(ValueError, "duplicate"):
            validate_answers(duplicate, self.assets)
        stale = dict(document, source_hashes={})
        with self.assertRaisesRegex(ValueError, "hashes"):
            validate_answers(stale, self.assets)
        unsupported = dict(document, answers=[dict(document["answers"][0], index=228)])
        with self.assertRaisesRegex(ValueError, "outside source art"):
            validate_answers(unsupported, self.assets)
        no_source = dict(document, answers=[dict(document["answers"][0], notes="")])
        with self.assertRaisesRegex(ValueError, "needs a frame"):
            validate_answers(no_source, self.assets)


if __name__ == "__main__":
    unittest.main()
