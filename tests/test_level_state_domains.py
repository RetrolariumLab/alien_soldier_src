"""Initial indexed-read safety; not a promise of compatible stage semantics."""

from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import level_state_domains as domains  # noqa: E402
from authoring import level_studio_model as model  # noqa: E402


class LevelStateDomainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.baseline = model.export_document(ROOT, "jp")
        cls.domains = domains.initial_domains(ROOT, cls.baseline["stage_slots"])

    def test_all_source_slots_select_their_actual_reader_capacities(self):
        expected = [(0, 60)] * 9 + [(4, 59)] * 8 + [(8, 82)] * 3 + [(12, 79)] * 6
        self.assertEqual(expected, [(item["process_offset"], item["entry_count"]) for item in self.domains])
        for profile in ("jp", "eu"):
            document = model.export_document(ROOT, profile)
            self.assertEqual([], domains.state_errors(ROOT, document, document))
            self.assertEqual([], model.document_errors(document, ROOT, profile))

    def test_last_aligned_word_allowed_next_word_and_odd_values_refused(self):
        for index in (0, 9, 17, 20):
            with self.subTest(index=index):
                document = deepcopy(self.baseline)
                name = document["stage_slots"][index]["configuration"]
                fields = next(item["fields"] for item in document["configurations"] if item["name"] == name)
                last = (self.domains[index]["entry_count"] - 1) * 2
                fields["state_offset"] = last
                self.assertEqual([], domains.state_errors(ROOT, document, self.baseline))
                for bad in (last + 2, last + 1, 0x8000, 0xFFFF):
                    fields["state_offset"] = bad
                    self.assertTrue(
                        any("state_offset" in value for value in domains.state_errors(ROOT, document, self.baseline))
                    )

    def test_route_switch_uses_destination_slot_reader_not_record_name(self):
        document = deepcopy(self.baseline)
        document["stage_slots"][0]["configuration"] = "Stage26ConfigRecord"
        errors = model.document_errors(document, ROOT, "jp")
        self.assertTrue(any("EarlyStage_StateHandlerOffsets" in error and "slot 0" in error for error in errors))
        next(item for item in document["configurations"] if item["name"] == "Stage26ConfigRecord")["fields"][
            "state_offset"
        ] = 0
        self.assertEqual([], domains.state_errors(ROOT, document, self.baseline))

    def test_shared_configuration_must_fit_every_current_consumer(self):
        document = deepcopy(self.baseline)
        document["stage_slots"][9]["configuration"] = "Stage1ConfigRecord"
        document["configurations"][0]["fields"]["state_offset"] = 118
        errors = domains.state_errors(ROOT, document, self.baseline)
        self.assertTrue(any("MidgameStateHandlerOffsets" in error for error in errors))
        self.assertFalse(any("EarlyStage_StateHandlerOffsets" in error for error in errors))

    def test_unselected_record_preserved_but_unknown_initial_reader_locks_state_edit(self):
        document = deepcopy(self.baseline)
        record = next(
            item for item in document["configurations"] if item["name"] == "UnreferencedStage20Variant1ConfigRecord"
        )
        self.assertEqual([], domains.state_errors(ROOT, document, self.baseline))
        record["fields"]["state_offset"] += 2
        self.assertTrue(
            any("no selected initial reader" in error for error in domains.state_errors(ROOT, document, self.baseline))
        )

    def test_changed_reader_initial_assignment_and_unknown_process_fail_closed(self):
        for path, old, new in (
            (
                "src/stages/stage_process_dispatch.s",
                "move.w  (StageStateOffset).w,d0",
                "move.w  (StageTableIndex).w,d0",
            ),
            ("src/stages/object_loading.s", "clr.w   (StageProcessTableOffset).w", "clr.w   (StageStateOffset).w"),
            ("src/stages/stage_process_dispatch.s", "dc.l    Stage_DispatchEarlyStageState", "dc.l    UnknownProcess"),
            (
                "src/stages/configuration_records.s",
                "move.w  (a0)+,(StageStateOffset).w",
                "move.w  (a0),(StageStateOffset).w",
            ),
            (
                "src/stages/configuration.s",
                "                move.w  #4,(StageProcessTableOffset).w",
                "                bra.s   UnknownPath\n                move.w  #4,(StageProcessTableOffset).w",
            ),
        ):
            with self.subTest(path=path, old=old), tempfile.TemporaryDirectory() as directory:
                tree = Path(directory)
                for relative in domains.SOURCE_OWNERS:
                    destination = tree / relative
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(ROOT / relative, destination)
                destination = tree / path
                before = destination.read_text(encoding="utf-8")
                self.assertIn(old, before)
                destination.write_text(before.replace(old, new, 1), encoding="utf-8")
                with self.assertRaises(ValueError):
                    domains.initial_domains(tree, self.baseline["stage_slots"])

    def test_invalid_state_prevents_staged_writes_and_preserves_source(self):
        document = deepcopy(self.baseline)
        document["configurations"][0]["fields"]["state_offset"] = 1
        with mock.patch.object(model, "rebuild_configuration_text") as rebuild:
            with self.assertRaisesRegex(ValueError, "state_offset"):
                model.apply_document(document, ROOT, "jp", write=False)
            rebuild.assert_not_called()


class PaletteEffectDomainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.baseline = model.export_document(ROOT, "jp")

    def test_direct_palette_tables_define_offsets_not_palette_colors(self):
        self.assertEqual(
            {"palette_primary": frozenset(range(0, 20, 2)), "palette_secondary": frozenset(range(0, 8, 2))},
            model.palette_effect_index_domains(ROOT),
        )
        for field, last in (("palette_primary", 18), ("palette_secondary", 6)):
            for value in (0, 2, last):
                document = deepcopy(self.baseline)
                document["configurations"][0]["fields"][field] = value
                self.assertEqual([], model.document_errors(document, ROOT, "jp"))

    def test_all_thirty_original_records_are_preserved_for_both_profiles(self):
        for profile in ("jp", "eu"):
            document = model.export_document(ROOT, profile)
            self.assertEqual(30, len(document["configurations"]))
            self.assertEqual([], model.document_errors(document, ROOT, profile))
            self.assertEqual([], model.apply_document(document, ROOT, profile, write=False))

    def test_width_valid_odd_and_out_of_table_offsets_are_rejected(self):
        for profile in ("jp", "eu"):
            for field, values in (("palette_primary", (1, 3, 19, 20, 255)), ("palette_secondary", (1, 3, 7, 8, 255))):
                for value in values:
                    with self.subTest(profile=profile, field=field, value=value):
                        document = model.export_document(ROOT, profile)
                        document["configurations"][0]["fields"][field] = value
                        with mock.patch.object(model, "rebuild_configuration_text") as rebuild:
                            with self.assertRaisesRegex(
                                ValueError, field + " is not a reader-owned aligned table offset"
                            ):
                                model.apply_document(document, ROOT, profile, write=False)
                            rebuild.assert_not_called()

    def test_reader_writer_and_table_width_drift_fail_closed(self):
        mutations = (
            (model.PALETTE_EFFECT_SOURCE, "move.w  (PalettePrimaryIndex).w,d0", "move.w  (FrameCounter).w,d0"),
            (
                model.PALETTE_EFFECT_SOURCE,
                "movea.w Palette_SecondaryEffectOffsets(pc,d0.w),a0",
                "movea.l Palette_SecondaryEffectOffsets(pc,d0.w),a0",
            ),
            (
                model.PALETTE_EFFECT_SOURCE,
                "movea.w Palette_PrimaryEffectOffsets(pc,d0.w),a0",
                "andi.w #$FE,d0\n                movea.w Palette_PrimaryEffectOffsets(pc,d0.w),a0",
            ),
            (
                model.PALETTE_EFFECT_SOURCE,
                "dc.w    Palette_EffectReturn-Palette_UpdateSharedAnimatedColors",
                "dc.l    Palette_EffectReturn-Palette_UpdateSharedAnimatedColors",
            ),
            (model.CONFIG_SOURCE, "move.b  (a0)+,(PalettePrimaryIndex+1).w", "move.w  (a0)+,(PalettePrimaryIndex+1).w"),
            (
                model.CONFIG_SOURCE,
                "move.b  (a0)+,(PaletteSecondaryIndex+1).w",
                "move.b  (a0)+,(PalettePrimaryIndex+1).w",
            ),
        )
        for path, old, new in mutations:
            with self.subTest(path=path, old=old), tempfile.TemporaryDirectory() as directory:
                tree = Path(directory)
                for relative in (model.CONFIG_SOURCE, model.PALETTE_EFFECT_SOURCE):
                    destination = tree / relative
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(ROOT / relative, destination)
                destination = tree / path
                before = destination.read_text(encoding="utf-8")
                self.assertIn(old, before)
                destination.write_text(before.replace(old, new, 1), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "palette"):
                    model.palette_effect_index_domains(tree)

    def test_source_table_growth_changes_bounds_not_guessed_baseline_domain(self):
        with tempfile.TemporaryDirectory() as directory:
            tree = Path(directory)
            for relative in (model.CONFIG_SOURCE, model.PALETTE_EFFECT_SOURCE):
                destination = tree / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / relative, destination)
            path = tree / model.PALETTE_EFFECT_SOURCE
            text = path.read_text(encoding="utf-8")
            text = text.replace(
                "Palette_UpdateSharedAnimatedColors:",
                "                dc.w Palette_EffectReturn-Palette_UpdateSharedAnimatedColors\nPalette_UpdateSharedAnimatedColors:",
                1,
            )
            path.write_text(text, encoding="utf-8")
            self.assertEqual(frozenset(range(0, 22, 2)), model.palette_effect_index_domains(tree)["palette_primary"])

    def test_invalid_effect_offset_rolls_back_headless_state_and_gui_apply_all(self):
        from authoring import level_studio, level_studio_state

        for profile in ("jp", "eu"):
            studio = level_studio_state.open_stage(
                ROOT, 0, profile=profile, document=model.export_document(ROOT, profile)
            )
            before, scene, selection = studio.document(), studio.scene, studio.selection
            for field, value in (("palette_primary", 1), ("palette_secondary", 8)):
                values = dict(studio.configuration.fields)
                values["camera_x"] += 8
                values[field] = value
                with (
                    self.subTest(profile=profile, field=field),
                    mock.patch.object(level_studio_state, "open_stage") as reopened,
                ):
                    with self.assertRaisesRegex(ValueError, field + ".*aligned table offset"):
                        studio.set_configuration_fields(values)
                    window = object.__new__(level_studio.Window)
                    window.studio, window.configuration_fields = studio, {}
                    for name, item in values.items():
                        widget = mock.Mock()
                        widget.get.return_value = item
                        window.configuration_fields[name] = widget
                    for name in ("status", "_fold_current", "_changed", "load"):
                        setattr(window, name, mock.Mock())
                    window.apply_configuration()
                    self.assertIn(field, window.status.configure.call_args.kwargs["text"])
                    reopened.assert_not_called()
                    window._fold_current.assert_not_called()
                    window._changed.assert_not_called()
                    window.load.assert_not_called()
                self.assertEqual(before, studio.document())
                self.assertIs(scene, studio.scene)
                self.assertEqual(selection, studio.selection)
                self.assertFalse(studio.edited)


if __name__ == "__main__":
    unittest.main()
