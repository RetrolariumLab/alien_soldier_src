from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import animation_studio_model as model
import verify_symbols


def fixture(root: Path) -> dict:
    """A synthetic two-region cartridge, not runtime or preservation evidence."""
    for owner in ("src/data", "src/rendering", "config"):
        (root / owner).mkdir(parents=True)
    (root / "src/data/animations.s").write_text(
        "FirstAnimation: dc.w FirstSpriteMapping-*, 3\n"
        " dc.w FirstAnimation-*, 0\n"
        "SecondAnimation: dc.w SecondSpriteMapping-*, 4\n"
        " dc.w SecondAnimation-*, 0\n"
        "DynamicAnimation: dc.w DynamicSpriteMapping-*, 2\n"
        " dc.w DynamicAnimation-*, 0\n"
        "FirstSpriteMapping: dc.w $8000, $500, 0\n"
        "SecondSpriteMapping: dc.w $8000, $500, 1\n"
        "DynamicSpriteMapping: dc.w $8000\n"
        " dc.l FixtureArt+$05000000\n"
        " dc.w 0\n", encoding="utf-8")
    (root / "src/rendering/sprite_object_pipeline.s").write_text(
        "Anim_ResolveTimedMappingFrame:\n" + "\n".join(model.TIMED_READER_OPERATIONS)
        + "\n; End of function Anim_ResolveTimedMappingFrame\n", encoding="utf-8")
    jp = {"FirstAnimation": 0x100, "SecondAnimation": 0x110,
          "DynamicAnimation": 0x120, "FirstSpriteMapping": 0x180,
          "SecondSpriteMapping": 0x190, "DynamicSpriteMapping": 0x1A0,
          "FixtureArt": 0x300}
    # Prove the profiles independently, with genuinely different displacements.
    eu = {name: address + (0x200 if "Animation" in name else 0x220)
          for name, address in jp.items()}
    addresses = {"jp": jp, "eu": eu}
    profiles = json.loads((ROOT / "config/rom_profiles.json").read_text(encoding="utf-8"))
    document = model.export_document(root, "jp")
    for record in profiles["profiles"]:
        profile = record["id"]
        selected = addresses[profile]
        image = bytearray(0x200000)
        for script in document["scripts"]:
            origin = selected[script["name"]]
            for frame in script["frames"]:
                at = origin + frame["index"] * 4
                delta = selected[frame["target"]] - at
                image[at:at + 4] = ((delta & 0xFFFF).to_bytes(2, "big")
                                    + frame["duration"].to_bytes(2, "big"))
        for name, suffix in (("FirstSpriteMapping", 0), ("SecondSpriteMapping", 1)):
            at = selected[name]
            image[at:at + 6] = bytes.fromhex("80000500") + suffix.to_bytes(2, "big")
        at = selected["DynamicSpriteMapping"]
        image[at:at + 8] = (bytes.fromhex("8000")
                            + (0x05000000 + selected["FixtureArt"]).to_bytes(4, "big")
                            + bytes(2))
        record["reference_rom"]["filename"] = profile + "-synthetic.bin"
        record["reference_rom"]["sha256"] = hashlib.sha256(image).hexdigest()
        (root / record["reference_rom"]["filename"]).write_bytes(image)
    audit = [{"current_name": name, "address": "0x%06X" % address,
              "previous_name": "old_" + name, "legacy_name": "legacy_" + name}
             for name, address in sorted(jp.items())]
    rows = [{"current_name": name, "jp_address": "0x%06X" % jp[name],
             "eu_address": "0x%06X" % eu[name], "status": "assembled"}
            for name in sorted(jp)]
    identities = {item["id"]: {key: item["reference_rom"][key] for key in ("size", "sha256")}
                  for item in profiles["profiles"]}
    ledger = {"schema_version": 1, "profile": "eu", "origin_profile": "jp",
              "origin_identity_fields": list(verify_symbols.IDENTITY_FIELDS),
              "origin_identity_sha256": verify_symbols.origin_identity(audit),
              "original_roms": identities, "record_count": len(audit),
              "records_sha256": verify_symbols.canonical_sha256(rows), "records": rows,
              "generation": {"profiles": {
                  profile: {"resolved_flags": verify_symbols.PROFILE_FLAGS[profile],
                            "build_rom_sha256": identities[profile]["sha256"],
                            "original_rom_sha256": identities[profile]["sha256"],
                            "printed_byte_rows": 1, "listing_sha256": "0" * 64}
                  for profile in ("jp", "eu")}}}
    for name, value in (("rom_profiles.json", profiles), ("name_audit.json", {"records": audit}),
                        ("name_addresses_eu.json", ledger)):
        (root / "config" / name).write_text(json.dumps(value), encoding="utf-8")
    return addresses


def selected(document: dict, name: str) -> dict:
    return next(record for record in document["scripts"] if record["name"] == name)


class SignedWordTests(unittest.TestCase):
    def test_even_signed_boundaries_and_one_word_beyond(self):
        self.assertEqual(-32768, model.relative_pointer(0x10000, 0x8000))
        self.assertEqual(32766, model.relative_pointer(0x10000, 0x17FFE))
        for destination in (0x7FFE, 0x18000):
            with self.assertRaisesRegex(ValueError, "signed16"):
                model.relative_pointer(0x10000, destination)

    def test_addresses_are_typed_aligned_and_rom_owned(self):
        for origin, target in ((True, 0x100), (0x100, 1.0), (0x100, 0x17FFF),
                               (-2, 0x100), (0x100, 0x200000)):
            with self.assertRaisesRegex(ValueError, "aligned proved ROM"):
                model.relative_pointer(origin, target)

    def test_actual_far_pair_is_rejected_before_any_mapping_or_byte_match(self):
        ledger = json.loads((ROOT / "config/name_addresses_eu.json").read_text(encoding="utf-8"))
        rows = {row["current_name"]: row for row in ledger["records"]}
        for profile in ("jp", "eu"):
            origin = int(rows["SharedCombatSpriteAnimation00"][profile + "_address"], 16)
            target = int(rows["Stage12_TeddyBearSpriteMappingR"][profile + "_address"], 16)
            self.assertEqual(751922, target - origin)
            with self.assertRaisesRegex(ValueError, "signed16"):
                model.relative_pointer(origin, target)


class PointerDomainTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.addresses = fixture(self.root)

    def test_independent_no_listing_evidence_and_legal_static_retarget(self):
        displacements = []
        for profile in ("jp", "eu"):
            document = model.export_document(self.root, profile)
            evidence = model.pointer_evidence(self.root, profile, document)
            addresses = evidence[0]
            self.assertEqual(self.addresses[profile]["FirstAnimation"], addresses["FirstAnimation"])
            displacements.append(addresses["FirstSpriteMapping"] - addresses["FirstAnimation"])
            selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
            model.validate_document(document, self.root, profile)
        self.assertNotEqual(*displacements)

    def test_static_dynamic_consumer_domains_cannot_be_crossed(self):
        for profile in ("jp", "eu"):
            for name, target in (("FirstAnimation", "DynamicSpriteMapping"),
                                 ("DynamicAnimation", "FirstSpriteMapping")):
                document = model.export_document(self.root, profile)
                selected(document, name)["frames"][0]["target"] = target
                with self.assertRaisesRegex(ValueError, "static/dynamic consumer"):
                    model.validate_document(document, self.root, profile)

    def test_legal_jump_keeps_its_first_mapping_consumer_domain(self):
        document = model.export_document(self.root, "jp")
        selected(document, "FirstAnimation")["frames"][1]["target"] = "SecondAnimation"
        model.validate_document(document, self.root, "jp")
        selected(document, "FirstAnimation")["frames"][1]["target"] = "DynamicAnimation"
        with self.assertRaisesRegex(ValueError, "static/dynamic consumer"):
            model.validate_document(document, self.root, "jp")

    def test_jump_destinations_are_signed_and_their_whole_source_is_authenticated(self):
        for profile in ("jp", "eu"):
            document = model.export_document(self.root, profile)
            evidence = model.pointer_evidence(self.root, profile, document)
            caller = selected(document, "FirstAnimation")
            changed = dict(caller["frames"][1], target="SecondAnimation")
            originals = {record["name"]: record for record in document["scripts"]}
            addresses = dict(evidence[0])
            addresses["SecondAnimation"] += 0x10000
            self.assertIn("signed16", model.pointer_domain_error(
                caller, changed, originals, (addresses, evidence[1], evidence[2])))
            selected(document, "SecondAnimation")["frames"][0]["duration"] = 5
            self.assertIn("source caller encoding", model.pointer_domain_error(
                caller, changed, originals, evidence))

    def test_unknown_evidence_blocks_retarget_but_keeps_unmodified_references(self):
        document = model.export_document(self.root, "jp")
        (self.root / "config/name_addresses_eu.json").unlink()
        model.validate_document(document, self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["duration"] = 5
        model.validate_document(document, self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        with self.assertRaisesRegex(ValueError, "unknown/non-writable"):
            model.validate_document(document, self.root, "jp")

    def test_source_caller_or_mapping_byte_changes_cannot_authenticate_an_edit(self):
        for before, after in (("FirstSpriteMapping-*, 3", "FirstSpriteMapping-*, 7"),
                              ("$8000, $500, 1", "$8000, $500, 2")):
            with self.subTest(after=after):
                path = self.root / "src/data/animations.s"
                original = path.read_text(encoding="utf-8")
                path.write_text(original.replace(before, after), encoding="utf-8")
                document = model.export_document(self.root, "jp")
                selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
                with self.assertRaisesRegex(ValueError, "source.*(encoding|bytes) differ"):
                    model.validate_document(document, self.root, "jp")
                path.write_text(original, encoding="utf-8")

    def test_wrong_or_missing_cartridge_is_non_writable(self):
        document = model.export_document(self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        image = self.root / "jp-synthetic.bin"
        image.write_bytes(bytes(0x200000))
        with self.assertRaisesRegex(ValueError, "authenticated regional original"):
            model.validate_document(document, self.root, "jp")
        image.unlink()
        with self.assertRaisesRegex(ValueError, "unknown/non-writable"):
            model.validate_document(document, self.root, "jp")

    def test_wrong_ledger_hash_profile_and_duplicate_keys_are_non_writable(self):
        path = self.root / "config/name_addresses_eu.json"
        original = path.read_text(encoding="utf-8")
        document = model.export_document(self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        for mutation in (lambda value: value.update(records_sha256="0" * 64),
                         lambda value: value.update(profile="jp")):
            value = json.loads(original)
            mutation(value)
            path.write_text(json.dumps(value), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "frozen regional address evidence"):
                model.validate_document(document, self.root, "jp")
        path.write_text(original.replace('"schema_version": 1', '"schema_version": 1, "schema_version": 1'), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "duplicate animation"):
            model.validate_document(document, self.root, "jp")

    def test_malformed_generation_profiles_and_regional_proofs_are_non_writable(self):
        path = self.root / "config/name_addresses_eu.json"
        original = json.loads(path.read_text(encoding="utf-8"))
        document = model.export_document(self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        for malformed in (None, [], False, "not an object"):
            value = json.loads(json.dumps(original))
            value["generation"]["profiles"] = malformed
            path.write_text(json.dumps(value), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "unknown/non-writable.*generation profiles must be an object"):
                model.validate_document(document, self.root, "jp")
            for region in ("jp", "eu"):
                value = json.loads(json.dumps(original))
                value["generation"]["profiles"][region] = malformed
                path.write_text(json.dumps(value), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "unknown/non-writable.*profile proof must be an object: " + region):
                    model.validate_document(document, self.root, "jp")

    def test_address_evidence_top_levels_and_record_lists_are_structural_objects(self):
        document = model.export_document(self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        paths = [self.root / "config" / name for name in ("name_audit.json", "name_addresses_eu.json")]
        for path in paths:
            original = path.read_text(encoding="utf-8")
            for value in (None, [], False, "not an object"):
                path.write_text(json.dumps(value), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "unknown/non-writable.*address evidence must be an object"):
                    model.validate_document(document, self.root, "jp")
                path.write_text(original, encoding="utf-8")
                malformed = json.loads(original)
                malformed["records"] = value
                path.write_text(json.dumps(malformed), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "unknown/non-writable.*(records must be a list|frozen regional address evidence differs)"):
                    model.validate_document(document, self.root, "jp")
            path.write_text(original, encoding="utf-8")

    def test_malformed_origin_and_ledger_rows_report_value_error_without_writes(self):
        document = model.export_document(self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        source = self.root / "src/data/animations.s"
        source_before = source.read_bytes()
        for name in ("name_audit.json", "name_addresses_eu.json"):
            path = self.root / "config" / name
            original = path.read_text(encoding="utf-8")
            for value in (None, [], False, "not an object"):
                malformed = json.loads(original)
                malformed["records"][0] = value
                path.write_text(json.dumps(malformed), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "unknown/non-writable.*row must be an object"):
                    model.apply_document(document, self.root, "jp")
                self.assertEqual(source_before, source.read_bytes())
            if name == "name_audit.json":
                malformed = json.loads(original)
                del malformed["records"][0]["address"]
                path.write_text(json.dumps(malformed), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "identity fields"):
                    model.validate_document(document, self.root, "jp")
            path.write_text(original, encoding="utf-8")

    def test_present_unproved_listing_is_not_ignored_for_frozen_fallback(self):
        path = self.root / "build/main.lst"
        path.parent.mkdir()
        path.write_text("not an assembler listing\n", encoding="ascii")
        document = model.export_document(self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        with self.assertRaisesRegex(ValueError, "preservation listing profile/addresses"):
            model.validate_document(document, self.root, "jp")

    def test_comments_cannot_supply_missing_reader_operations(self):
        path = self.root / "src/rendering/sprite_object_pipeline.s"
        path.write_text(path.read_text(encoding="utf-8").replace(
            "adda.w (a4),a4", "; adda.w (a4),a4"), encoding="utf-8")
        document = model.export_document(self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        with self.assertRaisesRegex(ValueError, "reader contract changed"):
            model.validate_document(document, self.root, "jp")

    def test_unknown_dynamic_art_binding_is_not_an_editable_target(self):
        path = self.root / "src/data/animations.s"
        path.write_text(path.read_text(encoding="utf-8").replace(
            "FixtureArt+$05000000", "UnknownArt+$05000000"), encoding="utf-8")
        document = model.export_document(self.root, "jp")
        selected(document, "SecondAnimation")["frames"][0]["target"] = "DynamicSpriteMapping"
        with self.assertRaisesRegex(ValueError, "dynamic art address is unknown"):
            model.validate_document(document, self.root, "jp")

    def test_staged_apply_uses_explicit_canonical_validation_root(self):
        destination = self.root / "staged"
        (destination / "src/data").mkdir(parents=True)
        source = self.root / "src/data/animations.s"
        target = destination / "src/data/animations.s"
        target.write_bytes(source.read_bytes())
        document = model.export_document(self.root, "eu")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        with self.assertRaisesRegex(ValueError, "unknown/non-writable"):
            model.apply_document(document, destination, "eu")
        self.assertEqual(source.read_bytes(), target.read_bytes())
        self.assertEqual(["src/data/animations.s"], model.apply_document(
            document, destination, "eu", validation_root=self.root))
        self.assertIn("SecondSpriteMapping-*", target.read_text(encoding="utf-8"))
        self.assertIn("FirstSpriteMapping-*", source.read_text(encoding="utf-8"))

    def test_invalid_apply_leaves_all_sources_untouched(self):
        path = self.root / "src/data/animations.s"
        original = path.read_bytes()
        document = model.export_document(self.root, "jp")
        selected(document, "FirstAnimation")["frames"][0]["target"] = "DynamicSpriteMapping"
        with self.assertRaisesRegex(ValueError, "static/dynamic consumer"):
            model.apply_document(document, self.root, "jp")
        self.assertEqual(original, path.read_bytes())

    def test_boolean_frame_indices_and_integer_jump_flags_are_not_roles(self):
        for field, value in (("index", False), ("jump", 0), ("jump", 1)):
            document = model.export_document(self.root, "jp")
            selected(document, "FirstAnimation")["frames"][0][field] = value
            with self.assertRaisesRegex(ValueError, "(index|jump role)"):
                model.validate_document(document, self.root, "jp")

    def test_equal_valued_animation_count_aliases_are_not_source_metadata(self):
        original = model.export_document(self.root, "jp")
        changes = [(field, lambda doc, field=field: doc.update({field: float(doc[field])}))
                   for field in ("schema_version", "script_count", "frame_count", "jump_count")]
        changes.extend((
            ("boolean schema", lambda doc: doc.update(schema_version=True)),
            ("script frame count", lambda doc: doc["scripts"][0].update(
                frame_count=float(doc["scripts"][0]["frame_count"]))),
            ("floating frame index", lambda doc: doc["scripts"][0]["frames"][0].update(index=0.0)),
            ("floating duration", lambda doc: doc["scripts"][0]["frames"][0].update(duration=3.0)),
        ))
        for description, change in changes:
            with self.subTest(field=description):
                document = copy.deepcopy(original)
                change(document)
                with self.assertRaises(ValueError):
                    model.validate_document(document, self.root, "jp")

    def test_malformed_animation_inventories_raise_value_error_without_hashing_names(self):
        original = model.export_document(self.root, "jp")
        changes = (
            lambda doc: doc.update(scripts=None),
            lambda doc: doc["scripts"].__setitem__(0, None),
            lambda doc: doc["scripts"][0].update(name=[]),
            lambda doc: doc["scripts"][0].update(name={}),
            lambda doc: doc["scripts"][0].update(source_path=[]),
            lambda doc: doc["scripts"][0].update(frames=None),
            lambda doc: doc["scripts"][0]["frames"].__setitem__(0, None),
            lambda doc: doc["scripts"][0]["frames"][0].update(target=[]),
            lambda doc: doc["scripts"][0]["frames"][0].update(duration=[]),
            lambda doc: doc.update(frame_targets=[[]]),
        )
        for index, change in enumerate(changes):
            with self.subTest(mutant=index):
                document = copy.deepcopy(original)
                change(document)
                with self.assertRaises(ValueError):
                    model.validate_document(document, self.root, "jp")
        for document in (None, [], "not an animation document"):
            with self.subTest(document=document), self.assertRaises(ValueError):
                model.validate_document(document, self.root, "jp")

    def test_independent_script_order_is_not_a_packed_record_order(self):
        for profile in ("jp", "eu"):
            document = model.export_document(self.root, profile)
            document["scripts"].reverse()
            model.validate_document(document, self.root, profile)


class CanonicalSourceTests(unittest.TestCase):
    def test_both_source_documents_remain_zero_edit_without_new_pointer_evidence(self):
        with patch.object(model, "pointer_evidence", side_effect=AssertionError("unneeded")):
            for profile in ("jp", "eu"):
                self.assertEqual([], model.round_trip_errors(ROOT, profile))

    def test_actual_far_selection_rejects_validation_and_apply_in_both_profiles(self):
        ledger = json.loads((ROOT / "config/name_addresses_eu.json").read_text(encoding="utf-8"))
        for profile in ("jp", "eu"):
            addresses = {row["current_name"]: int(row[profile + "_address"], 16)
                         for row in ledger["records"] if row["status"] == "assembled"}
            document = model.export_document(ROOT, profile)
            selected(document, "SharedCombatSpriteAnimation00")["frames"][0]["target"] = "Stage12_TeddyBearSpriteMappingR"
            # A pointer-domain fixture proves the original far-pair failure
            # without requiring a private cartridge or pretending to capture it.
            with patch.object(model, "pointer_evidence", return_value=(addresses, b"", {})):
                with self.assertRaisesRegex(ValueError, "signed16"):
                    model.validate_document(document, ROOT, profile)
                with self.assertRaisesRegex(ValueError, "signed16"):
                    model.apply_document(document, ROOT, profile, write=False)


if __name__ == "__main__":
    unittest.main()
