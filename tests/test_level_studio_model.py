from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT), str(ROOT / "scripts")]

from authoring import level_studio_model as model  # noqa: E402


def model_tree() -> Path:
    """Copy only the source owners and payloads the placement model uses."""
    destination = Path(tempfile.mkdtemp())
    lists, _ = model.read_source_lists(ROOT)
    for relative in (
        model.SPAWN_SOURCE,
        model.HANDLER_SOURCE,
        model.CONFIG_SOURCE,
        model.INITIALIZER_SOURCE,
        model.SPAWN_DIRECTOR_SOURCE,
        model.PALETTE_EFFECT_SOURCE,
        Path("src/stages/gameplay_entry_states.s"),
        Path("src/stages/stage_process_dispatch.s"),
        Path("src/stages/early_stage_process_states.s"),
        Path("src/stages/stage10_to_stage13.s"),
        Path("src/stages/late_game_state_dispatch.s"),
        Path("src/stages/stage_and_boss_transition_states.s"),
        Path("src/stages/object_loading.s"),
        Path("src/stages/phase_loading.s"),
    ):
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / relative, target)
    for item in lists:
        if item.payload is None:
            continue
        target = destination / item.payload
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / item.payload, target)
    return destination


class BaselineTests(unittest.TestCase):
    def test_current_tree_has_a_zero_edit_round_trip(self) -> None:
        self.assertEqual([], model.round_trip_errors(ROOT, "jp"))
        self.assertEqual([], model.round_trip_errors(ROOT, "eu"))

    def test_inventory_is_counted_from_the_current_source(self) -> None:
        document = model.export_document(ROOT, "jp")
        self.assertEqual(19, len(document["spawn_lists"]))
        self.assertEqual(
            314,
            sum(len(item["entries"]) for item in document["spawn_lists"]),
        )
        self.assertEqual(295, len(document["object_handlers"]))
        self.assertEqual(30, len(document["configurations"]))
        self.assertEqual(26, len(document["stage_slots"]))
        self.assertEqual(
            "Stage1ConfigRecord", document["stage_slots"][0]["configuration"]
        )
        self.assertEqual(
            [0, 1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14, 23, 24, 25],
            sorted(model.editable_stage_slot_locations(ROOT)),
        )

    def test_serialized_document_is_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            first = Path(directory) / "first.json"
            second = Path(directory) / "second.json"
            document = model.export_document(ROOT, "jp")
            model.atomic_write_json(first, document)
            model.atomic_write_json(second, model.export_document(ROOT, "jp"))
            self.assertEqual(first.read_bytes(), second.read_bytes())
            self.assertEqual(document, model.load_document(first))


class ValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.document = model.export_document(ROOT, "jp")

    def test_spawn_bounds_follow_the_source_reader_and_pool_limit(self) -> None:
        source = (ROOT / "src/gameplay/object_spawner.s").read_text(
            encoding="utf-8")
        self.assertIn("addi.w  #$140,d7", source)
        self.assertIn("cmp.w   (a4),d7", source)
        self.assertIn("blt.s   Sys_ProcessSpawnList_SaveCursor", source)
        self.assertIn("lea     $C(a4),a4", source)
        self.assertIn("cmpa.w  #$DCA0,a5", source)
        self.assertEqual(0x7FFF, model.TERMINATOR)
        self.assertEqual(0xDCA0, max(self.document["slot_boundaries"]))

    def test_profile_and_inventory_cannot_be_relabelled(self) -> None:
        self.document["profile"] = "eu"
        self.document["spawn_lists"] = self.document["spawn_lists"][1:]
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertIn("profile differs from the source-owned value", errors)
        self.assertIn("spawn-list inventory differs from the source", errors)

    def test_fixed_capacity_rejects_added_or_removed_placements(self) -> None:
        item = next(
            record for record in self.document["spawn_lists"] if record["entries"]
        )
        item["entries"].append(dict(item["entries"][0]))
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("entry count" in error for error in errors))

    def test_object_types_and_pool_boundaries_must_be_real(self) -> None:
        entry = next(
            record["entries"][0]
            for record in self.document["spawn_lists"]
            if record["entries"]
        )
        entry["object_type"] = 0xFFFC
        entry["slot_first"] = 1
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("dispatch handler" in error for error in errors))
        self.assertTrue(any("object-pool boundary" in error for error in errors))

    def test_spawn_stop_word_and_out_of_pool_starts_are_not_editable_rows(self) -> None:
        entry = next(record["entries"][0] for record in self.document["spawn_lists"]
                     if record["entries"])
        entry["slot_first"] = 0xDCA0
        entry["slot_limit"] = 0xDCA0
        for x in (0x7FFF, 0x8000, 0xFFFF):
            with self.subTest(x=x):
                entry["x"] = x
                errors = model.document_errors(self.document, ROOT, "jp")
                self.assertTrue(any("x must precede the $7FFF stop word" in error
                                    for error in errors))
                self.assertTrue(any("slot_first is beyond the object pool" in error
                                    for error in errors))

    def test_slot_range_order_is_checked_without_rejecting_equal_bounds(self) -> None:
        record = next(record for record in self.document["spawn_lists"]
                      if record["name"] == "Stage10_ObjectSpawnList")
        self.assertEqual((0xDB20, 0xDB20),
                         (record["entries"][7]["slot_first"],
                          record["entries"][7]["slot_limit"]))
        self.assertEqual([], model.document_errors(self.document, ROOT, "jp"))
        record["entries"][7]["slot_first"] = 0xDB80
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("slot_first exceeds slot_limit" in error
                            for error in errors))

    def test_configuration_widths_and_pointer_symbols_are_checked(self) -> None:
        configuration = self.document["configurations"][0]
        configuration["fields"]["player_x"] = 0x100
        configuration["fields"]["spawn_list"] = "InventedObjectSpawnList"
        configuration["fields"]["palette_list"] = "InventedPaletteList"
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("player_x does not fit dc.b" in error for error in errors))
        self.assertTrue(any("spawn_list is not a known" in error for error in errors))
        self.assertTrue(any("palette_list is not a known" in error for error in errors))

    def test_configuration_table_domains_follow_the_readers_not_current_values(self) -> None:
        entry = (ROOT / "src/stages/gameplay_entry_states.s").read_text(encoding="utf-8")
        primary = entry.split("Stage_StreamGameplayEntryPrimaryPlane_Rows:", 1)[1].split(
            "; End of function Stage_UpdateGameplayEntry", 1)[0]
        secondary = entry.split("Stage_StreamGameplayEntrySecondaryPlane_Rows:", 1)[1].split(
            "Stage_FinishGameplayEntry:", 1)[0]
        self.assertIn("andi.w  #$7FFF,d0", primary)
        self.assertNotIn("andi.w", secondary)
        self.assertIn("move.l  -4(a0,d0.w)", primary)
        self.assertIn("move.l  -4(a0,d0.w)", secondary)
        director = (ROOT / model.SPAWN_DIRECTOR_SOURCE).read_text(encoding="utf-8")
        self.assertIn("move.w  (EnemySpawnDirectorState).w,d0", director)
        self.assertIn("movea.w EnemySpawn_DirectorHandlers(pc,d0.w),a0", director)
        self.assertEqual({
            "plane_a_mode": frozenset((0, 4, 8, 0x8004, 0x8008)),
            "plane_b_mode": frozenset((0, 4, 8)),
            "spawn_director": frozenset((0, 2, 4)),
            "palette_primary": frozenset(range(0, 20, 2)),
            "palette_secondary": frozenset(range(0, 8, 2)),
        }, model.configuration_index_domains(ROOT))
        fields = self.document["configurations"][0]["fields"]
        fields["spawn_director"] = 4  # Valid table entry, unused by baseline records.
        fields["plane_a_mode"] = 0x8004
        self.assertEqual([], model.document_errors(self.document, ROOT, "jp"))

    def test_malformed_configuration_offsets_are_not_width_valid_edits(self) -> None:
        for field, values in {
            "plane_a_mode": (1, 2, 3, 5, 6, 7, 9, 12, 0x8000, 0x8005, 0x800C, 0xFFFF),
            "plane_b_mode": (1, 2, 5, 6, 12, 0x8000, 0x8004, 0x8008, 0xFFFF),
            "spawn_director": (1, 3, 5, 6, 0x8000, 0xFFFF),
        }.items():
            for value in values:
                with self.subTest(field=field, value=value):
                    changed = deepcopy(self.document)
                    changed["configurations"][0]["fields"][field] = value
                    self.assertIn(
                        f"Stage1ConfigRecord: {field} is not a reader-owned aligned table offset",
                        model.document_errors(changed, ROOT, "jp"))

    def test_xi_tiger_unmasked_reader_keeps_its_separate_fixed_configuration(self) -> None:
        source = (ROOT / "src/stages/visual_asset_loading.s").read_text(encoding="utf-8")
        table = source.split("Stage_XiTigerConfigurationOffsets:", 1)[1].split(
            "Stage_ApplyXiTigerConfiguration:", 1)[0]
        self.assertEqual(1, table.count("dc.w"))
        self.assertIn("Stage_ApplyXiTigerConfiguration-Stage_ApplyXiTigerConfiguration", table)
        initializer = source.split("Stage_ApplyXiTigerConfiguration:", 1)[1].split(
            "; End of function Stage_ApplyXiTigerConfiguration", 1)[0]
        self.assertIn("lea     XiTigerStageConfigRecord(pc),a0", initializer)
        entry = (ROOT / "src/stages/gameplay_entry_states.s").read_text(encoding="utf-8")
        self.assertIn("jsr     (Stage_InitializeXiTigerState).l", entry)
        xi_reader = entry.split("XiTigerStage_StreamPrimaryPlane_Rows:", 1)[1].split(
            "XiTigerStage_AdvanceToSecondaryPlane:", 1)[0]
        self.assertNotIn("andi.w", xi_reader)
        self.assertIn("(a0,d0.w),(TilemapTransferBase).w", xi_reader)
        self.assertNotIn("XiTigerStageConfigRecord", {
            item["name"] for item in self.document["configurations"]})
        self.assertNotIn("Stage_ApplyXiTigerConfiguration", {
            slot["initializer"] for slot in self.document["stage_slots"]})

        self.document["stage_slots"][0]["configuration"] = "XiTigerStageConfigRecord"
        self.document["stage_slots"][0]["initializer"] = "Stage_ApplyXiTigerConfiguration"
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("slot 0 identity differs" in error for error in errors))
        self.assertTrue(any("slot 0 has no known configuration" in error for error in errors))

    def test_stage_routes_preserve_slot_identity_and_special_initializers(self) -> None:
        self.document["stage_slots"][0]["index"] = False
        self.document["stage_slots"][0]["initializer"] = "Stage_ApplyStage2Configuration"
        self.document["stage_slots"][7]["configuration"] = "Stage1ConfigRecord"
        self.document["stage_slots"][1]["configuration"] = "InventedConfigRecord"
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("slot 0 identity" in error for error in errors))
        self.assertTrue(any("slot 7 has a fixed" in error for error in errors))
        self.assertTrue(any("slot 1 has no known" in error for error in errors))


class StagedApplicationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tree = model_tree()

    def tearDown(self) -> None:
        shutil.rmtree(self.tree, ignore_errors=True)

    def test_unchanged_document_touches_nothing(self) -> None:
        document = model.export_document(self.tree, "jp")
        self.assertEqual([], model.apply_document(document, self.tree, "jp"))

    def test_bad_configuration_offset_prevents_every_staged_write(self) -> None:
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                document = model.export_document(self.tree, profile)
                document["configurations"][0]["fields"]["plane_b_mode"] = 0x8004
                next(item for item in document["spawn_lists"] if item["entries"])[
                    "entries"][0]["x"] += 1
                before = {path: path.read_bytes() for path in self.tree.rglob("*")
                          if path.is_file()}
                with self.assertRaisesRegex(ValueError, "plane_b_mode.*aligned table offset"):
                    model.apply_document(document, self.tree, profile)
                self.assertEqual(before, {path: path.read_bytes() for path in before})

    def test_table_capacity_is_read_from_the_staged_source(self) -> None:
        path = self.tree / "src/stages/gameplay_entry_states.s"
        text = path.read_text(encoding="utf-8")
        path.write_text(text.replace(
            "                dc.l    Gfx_ScrollVRAMTransferParameters\n",
            "                dc.l    Gfx_ScrollVRAMTransferParameters\n"
            "                dc.l    Gfx_DefaultVRAMTransferParameters\n", 1), encoding="utf-8")
        self.assertEqual(frozenset((0, 4, 8, 12)),
                         model.configuration_index_domains(self.tree)["plane_b_mode"])
        document = model.export_document(self.tree, "jp")
        document["configurations"][0]["fields"]["plane_b_mode"] = 12
        self.assertEqual([], model.document_errors(document, self.tree, "jp"))

    def test_one_source_placement_edit_changes_only_the_spawn_source(self) -> None:
        document = model.export_document(self.tree, "jp")
        item = next(
            record
            for record in document["spawn_lists"]
            if record["storage"] == "source" and record["entries"]
        )
        item["entries"][0]["x"] += 1
        changed = model.apply_document(document, self.tree, "jp")
        self.assertEqual([model.SPAWN_SOURCE.as_posix()], changed)
        reread = model.export_document(self.tree, "jp")
        again = next(
            record for record in reread["spawn_lists"] if record["name"] == item["name"]
        )
        self.assertEqual(item["entries"][0]["x"], again["entries"][0]["x"])

    def test_one_payload_edit_changes_only_its_staged_payload(self) -> None:
        document = model.export_document(self.tree, "jp")
        item = next(
            record
            for record in document["spawn_lists"]
            if record["storage"] == "payload" and record["entries"]
        )
        item["entries"][0]["y"] += 1
        changed = model.apply_document(document, self.tree, "jp")
        self.assertEqual([item["payload"]], changed)
        self.assertEqual([], model.round_trip_errors(self.tree, "jp"))

    def test_one_configuration_edit_changes_only_its_value_token(self) -> None:
        document = model.export_document(self.tree, "jp")
        configuration = document["configurations"][0]
        configuration["fields"]["camera_x"] = 0x180
        before = (self.tree / model.CONFIG_SOURCE).read_text(encoding="utf-8")
        changed = model.apply_document(document, self.tree, "jp")
        self.assertEqual([model.CONFIG_SOURCE.as_posix()], changed)
        after = (self.tree / model.CONFIG_SOURCE).read_text(encoding="utf-8")
        differing = [
            (left, right)
            for left, right in zip(before.split("\n"), after.split("\n"))
            if left != right
        ]
        self.assertEqual(1, len(differing))
        self.assertEqual(differing[0][0].replace("dc.w    0", "dc.w    $180", 1), differing[0][1])
        reread = model.export_document(self.tree, "jp")
        self.assertEqual(0x180, reread["configurations"][0]["fields"]["camera_x"])

    def test_plain_stage_route_edits_only_its_initializer_operand(self) -> None:
        document = model.export_document(self.tree, "jp")
        document["stage_slots"][0]["configuration"] = "Stage2ConfigRecord"
        before = (self.tree / model.INITIALIZER_SOURCE).read_text(encoding="utf-8")
        changed = model.apply_document(document, self.tree, "jp")
        self.assertEqual([model.INITIALIZER_SOURCE.as_posix()], changed)
        after = (self.tree / model.INITIALIZER_SOURCE).read_text(encoding="utf-8")
        self.assertEqual(
            before.replace("lea     Stage1ConfigRecord(pc),a0",
                           "lea     Stage2ConfigRecord(pc),a0", 1), after)
        self.assertEqual("Stage2ConfigRecord",
                         model.export_document(self.tree, "jp")["stage_slots"][0]
                         ["configuration"])
        self.assertEqual([], model.round_trip_errors(self.tree, "jp"))

    def test_all_sixteen_plain_routes_round_trip_together(self) -> None:
        document = model.export_document(self.tree, "eu")
        editable = model.editable_stage_slot_locations(self.tree)
        for index in editable:
            slot = document["stage_slots"][index]
            slot["configuration"] = (
                "Stage2ConfigRecord" if slot["configuration"] == "Stage1ConfigRecord"
                else "Stage1ConfigRecord")
        self.assertEqual([model.INITIALIZER_SOURCE.as_posix()],
                         model.apply_document(document, self.tree, "eu"))
        reread = model.export_document(self.tree, "eu")
        for index in editable:
            self.assertEqual(document["stage_slots"][index]["configuration"],
                             reread["stage_slots"][index]["configuration"])
        self.assertEqual([], model.round_trip_errors(self.tree, "eu"))


if __name__ == "__main__":
    unittest.main()
