from __future__ import annotations

import hashlib
import io
import sys
import unittest
from contextlib import redirect_stderr
from dataclasses import replace
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import check_map_references as audit  # noqa: E402
from authoring.stage_tilemap_model import AssetCommand, Descriptor, Tilemap  # noqa: E402


def fixture():
    ram = bytearray(audit.RAM_SIZE)
    ram[0x6000:0x6040] = b"\1" * 64
    ram[0x4020:0x4040] = b"\x12\x34" * 16
    return Tilemap("fixture", ("fixture-list",), bytes(ram),
                   Descriptor("fixture-descriptor", 0xFFFF7000, 0xFFFF6000,
                              0xFFFF4000, False, 0x4000),
                   (("fixture-list", "coarse", 0x7000, 1024),
                    ("fixture-list", "chunks", 0x6000, 64),
                    ("fixture-list", "patterns", 0x4020, 32)))


class MapReferenceInventoryTests(unittest.TestCase):
    def test_complete_period_has_exact_counts_and_repeatable_graph_digest(self):
        plane = fixture()
        report, witness, patterns = audit.plane_facts(plane)
        self.assertEqual(1048576, report["counts"]["valid"])
        self.assertEqual(0, report["unloaded"])
        self.assertEqual(0, report["unowned"])
        self.assertEqual(3, len(report["writer_ranges"]))
        self.assertEqual([1024, 64, 32], [item["final_owned_bytes"] for item in report["writer_ranges"]])
        self.assertEqual((1023, 0, 0, 0), witness)
        self.assertEqual(0xFFFF, patterns[1][1])
        self.assertEqual(report, audit.plane_facts(plane)[0])

    def test_canonical_unloaded_coarse_target_is_inventory_not_a_failure(self):
        plane = fixture()
        ram = bytearray(plane.ram)
        ram[0x7000] = 0xFF
        report, _, _ = audit.plane_facts(replace(plane, ram=ram))
        self.assertEqual(1024, report["counts"]["unloaded_chunk"])
        self.assertEqual(1048576 - 1024, report["counts"]["valid"])

    def test_final_split_pattern_writer_is_not_owned_as_one_word(self):
        plane = fixture()
        late = ("later-list", "half-pattern-word", 0x4020, 1)
        report, _, _ = audit.plane_facts(replace(plane, written=plane.written + (late,)))
        self.assertEqual(65536, report["counts"]["unowned_pattern"])
        self.assertEqual(983040, report["counts"]["valid"])
        self.assertEqual(31, report["writer_ranges"][2]["final_owned_bytes"])
        self.assertEqual(1, report["writer_ranges"][3]["final_owned_bytes"])

    def test_partial_coarse_and_chunk_writers_account_for_every_unowned_read(self):
        plane = fixture()
        for index, length, key in ((0, 512, "unowned_coarse"), (1, 32, "unowned_chunk")):
            with self.subTest(role=key):
                written = list(plane.written)
                written[index] = (*written[index][:3], length)
                report, _, _ = audit.plane_facts(replace(plane, written=tuple(written)))
                self.assertEqual(524288, report["counts"][key])
                self.assertEqual(524288, report["counts"]["valid"])
                self.assertEqual(audit.TILES_PER_PLANE, sum(report["counts"].values()))

    def test_all_unloaded_descriptor_is_reported_without_claiming_a_gameplay_map(self):
        plane = replace(fixture(), written=())
        report, witness, patterns = audit.plane_facts(plane)
        self.assertEqual(audit.TILES_PER_PLANE, report["counts"]["unowned_coarse"])
        self.assertEqual(0, report["counts"]["valid"])
        probes = audit.mutation_probes(plane, "plane_b", "unloaded fixture", witness, patterns)
        self.assertTrue(all(item["status"] == "not_applicable" for item in probes))
        self.assertTrue(all(item["why"] == "no source-valid read" for item in probes))

    def test_map_word_edit_changes_graph_digest_without_changing_validity(self):
        plane = fixture()
        original = audit.plane_facts(plane)[0]
        ram = bytearray(plane.ram)
        ram[0x4020] ^= 1
        changed = audit.plane_facts(replace(plane, ram=ram))[0]
        self.assertEqual(original["counts"], changed["counts"])
        self.assertNotEqual(original["graph_sha256"], changed["graph_sha256"])

    def test_new_invalid_coarse_and_chunk_mutants_are_rejected_without_source_edits(self):
        plane = replace(fixture(), y_offset=16)
        source_hash = hashlib.sha256(plane.ram).hexdigest()
        _, witness, patterns = audit.plane_facts(plane)
        for plane_name in ("plane_a", "plane_b"):
            probes = audit.mutation_probes(plane, plane_name, "periodic fixture", witness, patterns)
            self.assertEqual(["coarse", "chunk"], [item["role"] for item in probes])
            self.assertTrue(all(item["status"] == "rejected" for item in probes), probes)
            self.assertIn("coarse index $FF", probes[0]["guard_error"])
            self.assertIn("chunk index $FF", probes[1]["guard_error"])
            self.assertIn(plane_name, probes[0]["guard_error"])
        self.assertEqual(source_hash, hashlib.sha256(plane.ram).hexdigest())

    def test_guard_accepting_a_new_invalid_reference_fails_the_gate(self):
        plane = fixture()
        _, witness, patterns = audit.plane_facts(plane)
        with mock.patch.object(audit, "periodic_reference_error", return_value=None):
            with self.assertRaisesRegex(ValueError, "accepted a new invalid coarse"):
                audit.mutation_probes(plane, "plane_a", "fixture", witness, patterns)

    def test_invalid_ram_or_writer_ranges_fail_closed(self):
        plane = fixture()
        for malformed in (
            replace(plane, ram=b"short"),
            replace(plane, written=(("list", "source", audit.RAM_SIZE - 1, 2),)),
            replace(plane, descriptor=replace(plane.descriptor, coarse=audit.RAM_BASE - 1)),
        ):
            with self.subTest(plane=malformed.name):
                with self.assertRaises(ValueError):
                    audit.plane_facts(malformed)


class StaticScopeTests(unittest.TestCase):
    def read(self):
        plane = fixture()
        configuration = SimpleNamespace(name="config", plane_a_mode=4, plane_b_mode=4,
                                        camera_y=16, secondary_camera_y=0)
        return {"loaders": ["loader", "procedural"], "configurations": [configuration, configuration],
                "tilemaps": [plane, plane], "descriptors": {plane.descriptor.name: plane.descriptor},
                "plane_tables": {audit.PLANE_A_TABLE: [plane.descriptor.name], audit.PLANE_B_TABLE: [plane.descriptor.name]},
                "not_reproduced": {1: "source-owned procedural route"}}

    def test_same_map_secondary_descriptor_is_audited_even_if_flat_renderer_suppresses_it(self):
        read = self.read()
        built = SimpleNamespace(tilemap=read["tilemaps"][0], plane_b=None, missing_codecs=(),
                                planes=("fixture", "same map, omitted from flat preview"))
        with mock.patch.object(audit, "scene", return_value=built):
            records = list(audit.stage_planes(ROOT, read, {"stage_rendering": {"stage_table_entries": 2}}))
        self.assertEqual(4, len(records))
        self.assertEqual("audited", records[1][0]["status"])
        self.assertFalse(records[1][0]["renderer_drawable"])
        self.assertEqual(16, records[1][1].y_offset)
        self.assertTrue(all(record[0]["status"] == "excluded" for record in records[2:]))
        self.assertTrue(all(record[0]["why"] == "source-owned procedural route" for record in records[2:]))

    def test_missing_configuration_or_scene_is_an_error_not_a_silent_exclusion(self):
        read = self.read()
        read["configurations"][0] = None
        with self.assertRaisesRegex(ValueError, "has no configuration"):
            list(audit.stage_planes(ROOT, read, {"stage_rendering": {"stage_table_entries": 2}}))
        with mock.patch.object(audit, "scene", side_effect=ValueError("unavailable scene")):
            with self.assertRaisesRegex(ValueError, "unavailable scene"):
                list(audit.stage_planes(ROOT, self.read(), {"stage_rendering": {"stage_table_entries": 2}}))

    def test_bad_output_path_is_rejected_before_any_audit(self):
        with mock.patch.object(audit, "audit") as run, redirect_stderr(io.StringIO()):
            self.assertEqual(1, audit.main(["--root", str(ROOT), "--output", "docs/not-a-report.json"]))
        run.assert_not_called()

    def test_missing_compressed_ram_payload_is_not_reported_as_a_canonical_hole(self):
        read = {"tilemaps": [fixture()], "not_reproduced": {}, "bodies": {}, "data": {},
                "lists": {"fixture-list": (AssetCommand(6, "missing-data", 0x4000),)}}
        with self.assertRaisesRegex(ValueError, "RAM payload is unavailable"):
            audit.require_scene_sources(read, {"supported": []})


if __name__ == "__main__":
    unittest.main()
