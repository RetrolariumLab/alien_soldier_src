from __future__ import annotations

import sys
import contextlib
import copy
import hashlib
import io
import json
import tempfile
import unittest
import zlib
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import verify_symbols  # noqa: E402
import derive_profile_name_addresses as derive  # noqa: E402


class VerifySymbolsTests(unittest.TestCase):
    def test_listing_retains_aliases_and_normalizes_ram_addresses(self) -> None:
        def row(address: int, source: str) -> str:
            return f"(1)  1/ {address:7X} :".ljust(40) + source + "\n"

        with tempfile.TemporaryDirectory() as directory:
            listing = Path(directory) / "main.lst"
            listing.write_text(
                row(0x1F494, "WeaponSetup_IdleState: rts")
                + row(0x1F494, "WeaponSetup_IdleAlias: rts")
                + row(0, "StageTimeRemaining equ $FFFFA270"),
                encoding="latin-1",
            )
            names, errors = verify_symbols.load_all_listing_names(listing)
        self.assertEqual([], errors)
        self.assertEqual(0x1F494, names["WeaponSetup_IdleState"])
        self.assertEqual(0x1F494, names["WeaponSetup_IdleAlias"])
        self.assertEqual(0xFFA270, names["StageTimeRemaining"])

    def test_name_audit_requires_every_exact_listing_address(self) -> None:
        records = [
            {"current_name": "WeaponSetup_IdleState", "address": "0x000053"},
            {"current_name": "StageTimeRemaining", "address": "0xFFA270"},
            {"current_name": "MissingName", "address": "0x1234"},
        ]
        errors = verify_symbols.validate_name_audit_addresses(
            records,
            {"WeaponSetup_IdleState": 0x1F494, "StageTimeRemaining": 0xFFA270},
        )
        self.assertEqual(2, len(errors))
        self.assertIn("0x000053; listing has 0x01F494", errors[0])
        self.assertIn("MissingName", errors[1])

    def test_runtime_offsets_resolve_to_base_symbol(self) -> None:
        layout = {"rom_image": {"landmarks": [{"symbol": "Reset", "address": "0x200"}]}}
        runtime = {
            "scenarios": [
                {
                    "expectations": [
                        {
                            "symbol": "Entity_ObjectPool",
                            "offset": "0x1E0",
                            "address": "0xFFC800",
                        }
                    ]
                }
            ]
        }
        self.assertEqual(
            {"Reset": 0x200, "Entity_ObjectPool": 0xFFC620},
            verify_symbols.required_symbols(layout, runtime),
        )

    def test_validation_requires_canonical_name_and_minimum(self) -> None:
        errors = verify_symbols.validate(
            {0x200: "Reset"},
            {"Reset": 0x200},
            {"Reset": 0x200, "GameModeIndex": 0xFFA284},
            minimum=2,
        )
        self.assertEqual(2, len(errors))
        self.assertIn("expected at least 2", errors[0])
        self.assertIn("GameModeIndex", errors[1])


class RegionalProvenanceTests(unittest.TestCase):
    def fixture(self, root):
        profiles = json.loads((ROOT / "config/rom_profiles.json").read_text())
        records = [
            {
                "current_name": "Reset",
                "address": "0x000002",
                "previous_name": "sub_2",
                "legacy_name": "sub_2",
                "basis": ["not duplicated"],
            },
            {
                "current_name": "StageTimeRemaining",
                "address": "0xFFA270",
                "previous_name": "word_FFA270",
                "legacy_name": "word_FFA270",
            },
        ]

        def row(address, field, source):
            return ("(1)  1/ %7X : %s" % (address, field)).ljust(40) + source + "\n"

        listings = {}
        for profile, address in (("jp", 2), ("eu", 4)):
            entry = next(item for item in profiles["profiles"] if item["id"] == profile)
            image = bytes(address) + bytes.fromhex("4E75") + bytes(8 - address - 2)
            reference = entry["reference_rom"]
            reference.update(
                filename="original_%s.bin" % profile,
                size=len(image),
                sha256=hashlib.sha256(image).hexdigest(),
                sha1=hashlib.sha1(image).hexdigest(),
                md5=hashlib.md5(image).hexdigest(),
                crc32="%08X" % (zlib.crc32(image) & 0xFFFFFFFF),
            )
            for name in (entry["output"], reference["filename"]):
                (root / name).write_bytes(image)
            listing = root / entry["listing"]
            listing.parent.mkdir(parents=True, exist_ok=True)
            flags = verify_symbols.PROFILE_FLAGS[profile]
            listing.write_text(
                row(address, "4E75", "Reset: rts")
                + row(0, "=$FFFFA270", "StageTimeRemaining equ $FFFFA270")
                + row(0, "=$0", "BuildProfileEU equ $0")
                + "Symbol Table (* = unused):\n"
                + " BUILDPROFILEEU : %X - | BUILDPROFILEJP : %X - |\n"
                % (flags["BuildProfileEU"], flags["BuildProfileJP"])
                + " RESET : %X C | STAGETIMEREMAINING : FFFFA270 I |\n" % address,
                encoding="latin-1",
            )
            listings[profile] = listing
        (root / "config").mkdir()
        (root / "config/rom_profiles.json").write_text(json.dumps(profiles), encoding="utf-8")
        (root / "config/name_audit.json").write_text(json.dumps({"records": records}), encoding="utf-8")
        return records, listings

    def test_generator_freezes_explicit_pairs_original_images_and_origin_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            records, listings = self.fixture(root)
            ledger = derive.derive(root)
            self.assertEqual(2, ledger["record_count"])
            self.assertEqual(
                {"current_name": "Reset", "jp_address": "0x000002", "eu_address": "0x000004", "status": "assembled"},
                ledger["records"][0],
            )
            self.assertEqual("0xFFA270", ledger["records"][1]["eu_address"])
            self.assertNotIn("basis", json.dumps(ledger))
            names, errors = verify_symbols.load_all_listing_names(listings["eu"])
            self.assertEqual([], errors)
            profiles = verify_symbols.load_profiles(root / "config/rom_profiles.json")
            self.assertEqual([], verify_symbols.validate_profile_address_map(records, names, ledger, profiles))
            self.assertEqual(
                {"BuildProfileEU": 1, "BuildProfileJP": 0}, verify_symbols.load_profile_flags(listings["eu"])
            )

    def test_runtime_ledger_rejects_missing_extra_renamed_origin_profile_and_address_drift(self):
        for mutation in (
            "missing",
            "extra",
            "duplicate",
            "rename",
            "JP_address",
            "EU_address",
            "RAM_address",
            "legacy",
            "previous",
            "origin_address",
            "profile",
            "ROM_hash",
            "proof",
            "null",
        ):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                records, listings = self.fixture(root)
                ledger = derive.derive(root)
                names, _errors = verify_symbols.load_all_listing_names(listings["eu"])
                if mutation == "missing":
                    ledger["records"].pop()
                elif mutation == "extra":
                    ledger["records"].append(dict(ledger["records"][0], current_name="NonAudited"))
                elif mutation == "duplicate":
                    ledger["records"][1] = copy.deepcopy(ledger["records"][0])
                elif mutation == "rename":
                    ledger["records"][0]["current_name"] = "Renamed"
                elif mutation == "JP_address":
                    ledger["records"][0]["jp_address"] = "0x000003"
                elif mutation == "EU_address":
                    ledger["records"][0]["eu_address"] = "0x000005"
                elif mutation == "RAM_address":
                    ledger["records"][1]["eu_address"] = "0xFFA272"
                elif mutation == "legacy":
                    records[0]["legacy_name"] = "different_legacy"
                elif mutation == "previous":
                    records[0]["previous_name"] = "different_origin"
                elif mutation == "origin_address":
                    records[0]["address"] = "0x000003"
                elif mutation == "profile":
                    ledger["profile"] = "jp"
                elif mutation == "ROM_hash":
                    ledger["original_roms"]["eu"]["sha256"] = "0" * 64
                elif mutation == "proof":
                    ledger.pop("generation")
                elif mutation == "null":
                    ledger["records"][0]["eu_address"] = None
                # Semantic checks must reject drift even with a recomputed inventory hash.
                ledger["records_sha256"] = verify_symbols.canonical_sha256(ledger["records"])
                profiles = verify_symbols.load_profiles(root / "config/rom_profiles.json")
                self.assertTrue(verify_symbols.validate_profile_address_map(records, names, ledger, profiles))

    def test_listing_drift_is_not_used_to_regenerate_the_expected_address(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            records, listings = self.fixture(root)
            ledger = derive.derive(root)
            names, _errors = verify_symbols.load_all_listing_names(listings["eu"])
            names["Reset"] = 6
            errors = verify_symbols.validate_profile_address_map(
                records, names, ledger, verify_symbols.load_profiles(root / "config/rom_profiles.json")
            )
            self.assertTrue(any("says 0x000004; listing has 0x000006" in error for error in errors))
            self.assertEqual("0x000004", ledger["records"][0]["eu_address"])

    def test_generator_refuses_wrong_rom_wrong_listing_bytes_or_wrong_profile_flags(self):
        for mutation in ("ROM", "JP_address", "byte_field", "profile_flags", "missing_flags", "missing_EU_name"):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                _records, listings = self.fixture(root)
                if mutation == "ROM":
                    (root / "asbuilt_eu.bin").write_bytes(b"changed ROM")
                elif mutation == "JP_address":
                    listings["jp"].write_text(listings["jp"].read_text().replace("      2 :", "      4 :", 1))
                elif mutation == "byte_field":
                    listings["eu"].write_text(listings["eu"].read_text().replace("4E75", "4E71", 1))
                elif mutation == "profile_flags":
                    listings["eu"].write_text(listings["jp"].read_text())
                elif mutation == "missing_flags":
                    listings["eu"].write_text(
                        "\n".join(
                            line for line in listings["eu"].read_text().splitlines() if " BUILDPROFILEEU :" not in line
                        )
                    )
                elif mutation == "missing_EU_name":
                    listings["eu"].write_text(listings["eu"].read_text().replace("Reset:", "Renamed:"))
                with self.assertRaises(ValueError):
                    derive.derive(root)

    def test_publication_is_new_atomic_and_root_scoped(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fixture(root)
            ledger = derive.derive(root)
            output = derive.publish_new(root, "config/name_addresses_eu.json", ledger)
            before = output.read_bytes()
            self.assertEqual(ledger, verify_symbols.load_profile_address_map(output))
            with self.assertRaisesRegex(ValueError, "overwrite"):
                derive.publish_new(root, "config/name_addresses_eu.json", dict(ledger, profile="wrong"))
            self.assertEqual(before, output.read_bytes())
            self.assertFalse(list(output.parent.glob("*.tmp")))
            for name in ("../name.json", "src/name.json", "build/name.txt"):
                with self.subTest(name=name), self.assertRaises(ValueError):
                    derive.publish_new(root, name, ledger)

    def test_duplicate_json_keys_and_unresolved_flags_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ledger.json"
            path.write_text('{"profile":"eu","profile":"jp"}')
            with self.assertRaisesRegex(ValueError, "duplicate JSON key"):
                verify_symbols.load_profile_address_map(path)
        self.assertTrue(verify_symbols.validate_profile_flags("eu", {}))

    def test_inactive_listing_source_label_is_not_a_resolved_symbol(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _records, listings = self.fixture(root)
            listing = listings["eu"]
            text = listing.read_text().replace(" RESET : 4 C |", " OTHER : 4 C |")
            listing.write_text(text)
            parsed, _errors = verify_symbols.load_all_listing_names(listing)
            self.assertIn("Reset", parsed)
            self.assertNotIn("Reset", verify_symbols.load_resolved_listing_names(listing, {"Reset"}))
            with self.assertRaisesRegex(ValueError, "does not account for origin"):
                derive.derive(root)

    def exception_fixture(self, root):
        records, listings = self.fixture(root)
        record = {
            "current_name": verify_symbols.JP_ONLY_NAME,
            "address": "0x000006",
            "previous_name": "loc_35E",
            "legacy_name": "loc_35E",
        }
        records.append(record)
        (root / "config/name_audit.json").write_text(json.dumps({"records": records}))
        source = root / verify_symbols.EXCLUSION_SOURCE
        source.parent.mkdir(parents=True)
        source.write_bytes((ROOT / verify_symbols.EXCLUSION_SOURCE).read_bytes())
        with listings["jp"].open("a", encoding="latin-1") as stream:
            stream.write("(1)  1/       6 : 0000".ljust(40) + "Reset_ChecksumLoop: nop\n")
            stream.write(" RESET_CHECKSUMLOOP : 6 C |\n")
        with listings["eu"].open("a", encoding="latin-1") as stream:
            stream.write("(1)  1/       6 :".ljust(40) + "Reset_ChecksumLoop: nop\n")
        return records, listings

    def test_only_named_exclusion_requires_real_JP_symbol_EU_absence_and_exact_source(self):
        for mutation in (None, "EU_present", "JP_missing", "JP_moved", "source", "proof", "other_name", "null_address"):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                records, listings = self.exception_fixture(root)
                ledger = derive.derive(root)
                eu = verify_symbols.load_resolved_listing_names(
                    listings["eu"], {item["current_name"] for item in records}
                )
                jp = verify_symbols.load_resolved_listing_names(
                    listings["jp"], {item["current_name"] for item in records}
                )
                excluded = next(row for row in ledger["records"] if row["status"] == "not_assembled")
                self.assertEqual(verify_symbols.JP_ONLY_NAME, excluded["current_name"])
                self.assertIsNone(excluded["eu_address"])
                if mutation == "EU_present":
                    eu[verify_symbols.JP_ONLY_NAME] = 6
                elif mutation == "JP_missing":
                    jp.pop(verify_symbols.JP_ONLY_NAME)
                elif mutation == "JP_moved":
                    jp[verify_symbols.JP_ONLY_NAME] = 4
                elif mutation == "source":
                    (root / verify_symbols.EXCLUSION_SOURCE).write_text("wrong source conditional")
                elif mutation == "proof":
                    excluded["exclusion"]["branch"] = "if"
                elif mutation == "other_name":
                    ledger["records"][0].update(
                        status="not_assembled", eu_address=None, exclusion=excluded["exclusion"]
                    )
                elif mutation == "null_address":
                    ledger["records"][0]["eu_address"] = None
                ledger["records_sha256"] = verify_symbols.canonical_sha256(ledger["records"])
                errors = verify_symbols.validate_profile_address_map(
                    records,
                    eu,
                    ledger,
                    verify_symbols.load_profiles(root / "config/rom_profiles.json"),
                    jp_listing_names=jp,
                    root=root,
                )
                self.assertEqual(mutation is None, not errors, errors)

    def test_JP_resolved_export_checks_profile_flags_and_each_export_address(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _records, listings = self.fixture(root)
            symbol_file = root / "symbols.txt"
            layout, runtime = root / "layout.json", root / "runtime.json"
            layout.write_text(json.dumps({"rom_image": {"landmarks": [{"symbol": "Reset", "address": "0x2"}]}}))
            runtime.write_text(json.dumps({"scenarios": []}))
            args = [
                "verify_symbols",
                "--symbols",
                str(symbol_file),
                "--layout",
                str(layout),
                "--runtime",
                str(runtime),
                "--listing",
                str(listings["jp"]),
                "--name-audit",
                str(root / "config/name_audit.json"),
                "--minimum",
                "2",
                "--resolved-exports",
            ]
            symbol_file.write_text("00000002 Reset\n00FFA270 StageTimeRemaining\n")
            with mock.patch.object(sys, "argv", args), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(0, verify_symbols.main())
            original_listing = listings["jp"].read_text()
            listings["jp"].write_text(original_listing.replace(" STAGETIMEREMAINING : FFFFA270 I |", ""))
            # An audit alias can be absent from the canonical export; strict JP
            # must still reject its inactive source-only provenance record.
            symbol_file.write_text("00000002 Reset\n")
            inactive_args = list(args)
            inactive_args[inactive_args.index("--minimum") + 1] = "1"
            with mock.patch.object(sys, "argv", inactive_args), contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(1, verify_symbols.main())
            self.assertIn("name-audit symbol missing from listing: StageTimeRemaining", output.getvalue())
            listings["jp"].write_text(original_listing)
            symbol_file.write_text("00000002 Reset\n00FFA272 StageTimeRemaining\n")
            with mock.patch.object(sys, "argv", args), contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(1, verify_symbols.main())
            self.assertIn("exported regional symbol differs", output.getvalue())
            listings["jp"].write_text(listings["eu"].read_text())
            with mock.patch.object(sys, "argv", args), contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(1, verify_symbols.main())
            self.assertIn("do not identify profile jp", output.getvalue())

    def test_profile_flags_ignore_source_spoofs_and_do_not_mask_non_boolean_values(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "main.lst"
            path.write_text(
                " BUILDPROFILEEU : 1 - | BUILDPROFILEJP : 0 - |\n"
                + "Symbol Table (* = unused):\n BUILDPROFILEEU : 0 - | BUILDPROFILEJP : 1 - |\n"
            )
            self.assertEqual(verify_symbols.PROFILE_FLAGS["jp"], verify_symbols.load_profile_flags(path))
            path.write_text("Symbol Table (* = unused):\n BUILDPROFILEEU : 1000001 - | BUILDPROFILEJP : 0 - |\n")
            self.assertTrue(verify_symbols.validate_profile_flags("eu", verify_symbols.load_profile_flags(path)))

    def test_error_output_is_bounded_but_retains_total(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            verify_symbols.print_errors(["failure%d" % index for index in range(15843)])
        lines = output.getvalue().splitlines()
        self.assertEqual(21, len(lines))
        self.assertIn("15843 validation errors", lines[-1])
        self.assertNotIn("failure20", output.getvalue())


if __name__ == "__main__":
    unittest.main()
