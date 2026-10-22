"""Guard negative static-reference claims without claiming runtime unreachability."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class UnreferencedStaticEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.audit = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        cls.reviews = {
            review["basis"]: review
            for review in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }
        cls.source = {
            path.relative_to(ROOT).as_posix(): path.read_text(encoding="utf-8")
            for path in (ROOT / "src").rglob("*")
            if path.suffix in {".s", ".inc"}
        }

    def assert_review(self, basis: str, members: tuple[tuple[str, str], ...]) -> None:
        review = self.reviews[basis]
        self.assertEqual(
            list(members),
            [(member["address"], member["current_name"]) for member in review["members"]],
        )
        for address, name in members:
            self.assertEqual(name, self.audit[address]["current_name"])
            self.assertIn(basis, self.audit[address]["basis"])

    def assert_no_direct_reference(self, name: str, address: str) -> None:
        hex_address = address.removeprefix("0x").lstrip("0")
        name_re = re.compile(rf"\b{re.escape(name)}\b")
        literal_re = re.compile(rf"\$0*{hex_address}\b", re.IGNORECASE)
        definition_re = re.compile(rf"^\s*{re.escape(name)}:\s*$")
        definitions = 0
        for path, source in self.source.items():
            for lineno, line in enumerate(source.splitlines(), 1):
                executable = line.partition(";")[0]
                if definition_re.fullmatch(executable):
                    definitions += 1
                    continue
                self.assertIsNone(name_re.search(executable), f"{path}:{lineno} references {name}")
                self.assertIsNone(literal_re.search(executable), f"{path}:{lineno} uses ROM address {address}")
        self.assertEqual(1, definitions, f"expected one definition of {name}")

    def test_four_unreferenced_entrypoint_pairs_have_no_direct_source_refs(self) -> None:
        groups = (
            (
                "No reconstructed call or table refers to this entrypoint.",
                (
                    ("0x0548EE", "UnreferencedInitializeNineAuxiliarySprites"),
                    ("0x05491C", "UnreferencedUpdateNineAuxiliarySpritePositions"),
                ),
            ),
            (
                "No reconstructed code or data reference reaches this routine.",
                (
                    ("0x01CB32", "UnreferencedToggleFrameTimingMarkers"),
                    ("0x01CC98", "UnreferencedAppendFixedOAMEntries"),
                ),
            ),
            (
                "No reconstructed source call or table reference reaches this helper.",
                (
                    ("0x003A9C", "UnreferencedAdjustAndMirrorPaletteRange"),
                    ("0x003B72", "UnreferencedAddWrappingColorAdjustmentToPairedEntry"),
                ),
            ),
            (
                "No reconstructed static caller reaches the alternate entry.",
                (
                    ("0x0102AC", "UnreferencedAdvanceTrainScrollWithNop"),
                    ("0x0102DE", "UnreferencedUpdateQuarterScrollWithNop"),
                ),
            ),
        )
        for basis, members in groups:
            with self.subTest(basis=basis):
                self.assert_review(basis, members)
                for address, name in members:
                    self.assert_no_direct_reference(name, address)

        aux = self.source["src/actors/unreferenced_nine_auxiliary_sprites.s"]
        self.assertIn("move.w  #8,d7", aux)
        self.assertIn("dbf     d7,UnreferencedInitializeNineAuxiliarySpritesLoop", aux)
        debug = self.source["src/debug/frame_timing_toggle.s"]
        self.assertIn("eori.b  #$80,(FrameTimingDebugFlag).w", debug)
        palette = self.source["src/rendering/palette_transitions.s"]
        self.assertIn("move.w  d6,(a1)+", palette)
        self.assertIn("move.w  d6,-$80(a0)", palette)
        scroll = self.source["src/rendering/camera_tracking_and_stage_scroll.s"]
        for name, successor in (
            ("UnreferencedAdvanceTrainScrollWithNop", "Scroll_AdvanceTrainHorizontalAndRenderTilemap"),
            ("UnreferencedUpdateQuarterScrollWithNop", "Scroll_UpdateQuarterHorizontalPosition"),
        ):
            self.assertRegex(
                scroll, rf"(?m)^{name}:\s*\n\s+nop[^\n]*\n; End of function {name}\n;[^\n]*\n^{successor}:"
            )

    def test_two_unreferenced_asset_lists_have_exact_loader_relationship(self) -> None:
        path = "src/stages/phase_loading.s"
        source = self.source[path]
        for stage, phase, offset, middle in (
            (2, 2, "8", "SharedStage18AndStage20MappingData7000"),
            (3, 5, "$C", "Stage3SharedMappingData7000"),
        ):
            with self.subTest(stage=stage, phase=phase):
                stem = f"UnreferencedStage{stage}Phase{phase}"
                loader = f"{stem}AssetLoader"
                listing = f"{stem}AssetLoadList"
                self.assert_no_direct_reference(loader, "0x011B60" if stage == 2 else "0x011CF8")
                loader_body = source.split(f"{loader}:", 1)[1].split(f"; End of function {loader}", 1)[0]
                self.assertIn(f"move.w  #{offset},(StageProcessTableOffset).w", loader_body)
                self.assertIn(f"lea     {listing}(pc),a0", loader_body)
                self.assertIn("jmp     Stage_DispatchAssetListLoaderByGameMode(pc)", loader_body)
                list_body = source.split(f"{listing}:", 1)[1].split("dc.w    $FFFF", 1)[0]
                self.assertEqual(5, list_body.count("dc.l"))
                self.assertIn(f"dc.l    {middle}", list_body)
                self.assertIn("dc.l    SharedSceneAndStageTileArt9000", list_body)
                self.assertIn(f"dc.l    {stem}TileArt0000", list_body)
        self.assert_review(
            "The adjacent unreferenced loader passes this five-record terminated graphics and mappings list to Stage_DispatchAssetListLoaderByGameMode; no reachable owner is proven.",
            (
                ("0x011B72", "UnreferencedStage2Phase2AssetLoadList"),
                ("0x011D0A", "UnreferencedStage3Phase5AssetLoadList"),
            ),
        )

    def test_bugmax_single_return_slots_have_no_direct_source_refs(self) -> None:
        members = (
            ("0x04D85C", "Projectile_BugmaxSineInactiveState"),
            ("0x04D8F8", "Boss_BugmaxOpeningHitFragmentUnusedStub"),
        )
        self.assert_review("This unreferenced single-return slot performs no update.", members)
        source = self.source["src/projectiles/bugmax.s"]
        for address, name in members:
            with self.subTest(address=address):
                self.assert_no_direct_reference(name, address)
                body = source.split(name + ":", 1)[1].split("; End of function " + name, 1)[0]
                instructions = [
                    line.partition(";")[0].strip() for line in body.splitlines() if line.partition(";")[0].strip()
                ]
                self.assertEqual(["rts"], instructions)


if __name__ == "__main__":
    unittest.main()
