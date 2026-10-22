"""Actual model/UI safety and source-count controls; no native execution."""

from copy import deepcopy
import hashlib
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import credits_text_model as model
from authoring import text_studio_state as state
from authoring import atomic_output

SOURCE = "src/credits/animated_glyph_sequence.s"
SOURCE_SHA = "6ca7facc80ecdb1cfd606d0bfeb2ff5a74307a61d180384754de0300ff95983a"


def consumer_counts(delay, count):
    """Independent BYTE-MOVE/full-WORD/byte-BEQ explanation, not CPU execution."""
    if any(type(value) is not int or not 0 <= value <= 255 for value in (delay, count)):
        raise ValueError("delay/count must be exact bytes")
    timer = (delay * 2) & 0xFFFF
    word_count = (timer & 0xFF00) | count
    return 0 if count == 0 else word_count


class CreditsSourceCountTests(unittest.TestCase):
    def test_complete_source_keeps_byte_count_high_byte_and_word_loop(self):
        raw = (ROOT / SOURCE).read_bytes()
        self.assertEqual(SOURCE_SHA, hashlib.sha256(raw).hexdigest())
        section = (
            raw.decode("utf-8")
            .split("CreditsGlyphSequence_ReadLowerRow:", 1)[1]
            .split("CreditsGlyphSequence_SpawnLowerRowLoop:", 1)[0]
        )
        instructions = [row.split(";", 1)[0].strip() for row in section.splitlines() if row.split(";", 1)[0].strip()]
        self.assertEqual(
            [
                "moveq   #0,d0",
                "move.b  (a1)+,d0",
                "add.w   d0,d0",
                "move.w  d0,(SharedSequenceTimer).l",
                "move.b  (a1)+,d0",
                "beq.w   CreditsGlyphSequence_CommitRecord",
                "move.w  d0,d1",
            ],
            instructions[:7],
        )
        self.assertEqual(["move.w  d0,d7", "subq.w  #1,d7"], instructions[-2:])

    def test_all_nonempty_high_delays_add_256_slots_but_empty_beq_skips(self):
        for count in range(1, 256):
            for delay in range(128, 256):
                self.assertEqual(count + 256, consumer_counts(delay, count))
        for delay in range(256):
            self.assertEqual(0, consumer_counts(delay, 0))

    def test_real_first_lower_count_cannot_turn_five_slots_into261(self):
        for profile in ("jp", "eu"):
            document = model.export_document(ROOT, profile)
            self.assertEqual(5, document["records"][0]["lower_count"])
            self.assertEqual(261, consumer_counts(128, document["records"][0]["lower_count"]))
            changed = deepcopy(document)
            changed["records"][0]["lower_delay"] = 128
            with self.assertRaisesRegex(ValueError, "invalid lower delay"):
                model.validate_document(changed, ROOT, profile)


class CreditsLowerDelayPolicyTests(unittest.TestCase):
    def documents(self, profile):
        return model.export_document(ROOT, profile)

    def test_original_encoding_and_counts_are_unchanged_both_profiles(self):
        for profile in ("jp", "eu"):
            doc = self.documents(profile)
            model.validate_document(doc, ROOT, profile)
            self.assertEqual([], model.apply_document(doc, ROOT, profile, write=False))
            self.assertEqual((ROOT / model.DATA_PATH).read_bytes(), model.encode_document(doc))
            self.assertEqual(37, doc["record_count"])
            self.assertEqual(874, doc["encoded_byte_count"])

    def test_nonempty_safe_boundaries_and_all_unsafe_delays_both_profiles(self):
        for profile in ("jp", "eu"):
            doc = self.documents(profile)
            for delay in (0, 96, 127):
                changed = deepcopy(doc)
                changed["records"][0]["lower_delay"] = delay
                self.assertEqual([], model.document_errors(changed, ROOT, profile))
            for delay in range(128, 256):
                changed = deepcopy(doc)
                changed["records"][0]["lower_delay"] = delay
                self.assertTrue(
                    any("invalid lower delay" in row for row in model.document_errors_against(changed, doc))
                )
                with self.assertRaisesRegex(ValueError, "invalid lower delay"):
                    model.validate_document(changed, ROOT, profile)

    def test_fixed_empty_row_keeps_its_full_unsigned_byte_delay_range(self):
        for profile in ("jp", "eu"):
            doc = self.documents(profile)
            self.assertEqual([14], [i for i, row in enumerate(doc["records"]) if row["lower_count"] == 0])
            for delay in (0, 127, 128, 255):
                changed = deepcopy(doc)
                changed["records"][14]["lower_delay"] = delay
                model.validate_document(changed, ROOT, profile)
                self.assertEqual(0, consumer_counts(delay, 0))

    def test_forged_edited_zero_count_does_not_bypass_immutable_source_bound(self):
        for profile in ("jp", "eu"):
            doc = self.documents(profile)
            changed = deepcopy(doc)
            changed["records"][0].update(lower_count=0, lower_glyphs=[], lower_delay=128)
            errors = model.document_errors(changed, ROOT, profile)
            self.assertTrue(any("lower_count differs" in row for row in errors))
            self.assertTrue(any("invalid lower delay" in row for row in errors))

    def test_gui_all37_lower_fields_use_the_same_safe_count_dependent_maximum(self):
        for profile in ("jp", "eu"):
            workspace = state.Workspace({"credits_text_sequence": self.documents(profile)})
            workspace.select_artifact("credits_text_sequence")
            fields = [(i, field) for i, field in enumerate(workspace.artifact_fields) if field.key == "lower_delay"]
            self.assertEqual(37, len(fields))
            for index, field in fields:
                workspace.select_field(index)
                maximum = 127 if field.container["lower_count"] else 255
                self.assertEqual(maximum, field.maximum)
                workspace.set_value(maximum)
                self.assertEqual(maximum, workspace.value)
                with self.assertRaises(ValueError):
                    workspace.set_value(maximum + 1)

    def test_bad_types_do_not_alias_unsigned_byte_or_helper_count(self):
        for value in (-1, 256, True, False, 127.0, "127", None):
            with self.assertRaises(ValueError):
                model.lower_delay_maximum(value)
            for profile in ("jp", "eu"):
                doc = self.documents(profile)
                doc["records"][0]["lower_delay"] = value
                with self.assertRaises(ValueError):
                    model.validate_document(doc, ROOT, profile)

    def test_unsafe_payload_fails_before_actual_atomic_writer_in_isolated_tree(self):
        doc = self.documents("jp")
        doc["records"][0]["lower_delay"] = 128
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            for relative in (
                model.DATA_PATH,
                "data/artunc/font.bin",
                "src/credits/main.s",
                "src/rendering/vdp_asset_transfers.s",
                "src/data/shared_frontend_and_gameplay_tile_art.s",
            ):
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / relative, target)
            original = (root / model.DATA_PATH).read_bytes()
            with mock.patch.object(
                atomic_output, "atomic_write_bytes", side_effect=AssertionError("must not reach writer")
            ) as writer:
                with self.assertRaisesRegex(ValueError, "invalid lower delay"):
                    model.apply_document(doc, root, "jp", write=True)
                writer.assert_not_called()
            self.assertEqual(original, (root / model.DATA_PATH).read_bytes())

    def test_safe_saved_model_has_only_the_intended_lower_delay_byte_changed(self):
        for profile in ("jp", "eu"):
            doc = self.documents(profile)
            doc["records"][0]["lower_delay"] = 127
            with tempfile.TemporaryDirectory() as name:
                path = Path(name) / "credits.json"
                model.atomic_write_json(path, doc)
                loaded = model.load_document(path)
                model.validate_document(loaded, ROOT, profile)
                self.assertEqual(doc, loaded)
                before = model.encode_document(self.documents(profile))
                after = model.encode_document(loaded)
                self.assertEqual(
                    [15], [i for i, pair in enumerate(zip(before, after, strict=True)) if pair[0] != pair[1]]
                )


if __name__ == "__main__":
    unittest.main()
