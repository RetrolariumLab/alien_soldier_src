from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import verify_relocation  # noqa: E402


class VerifyRelocationTests(unittest.TestCase):
    def test_source_text_survives_a_variable_byte_column(self) -> None:
        """The emitted bytes are as wide as the statement needs."""
        short = "(1)  176/   11F94 : 0000                Label: dc.w 0"
        long = "(1)  177/   11F96 : 0000 6000 0007 0011      dc.w 0, $6000, 7, $11"
        self.assertEqual("Label: dc.w 0", verify_relocation.source_text(short))
        self.assertEqual("dc.w 0, $6000, 7, $11", verify_relocation.source_text(long))

    def test_a_bare_label_is_attributed_to_the_directive_before_it(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "main.lst"
            path.write_text(
                '(1)    1/     100 : 4E71                Payload: binclude "data/x.bin"\n'
                "(1)    2/     200 :                     Payload_End:\n",
                encoding="utf-8",
            )
            listing = verify_relocation.Listing(path)
        self.assertEqual({"Payload": 0x100, "Payload_End": 0x200}, listing.symbols)
        # An address inside the payload lands on the bare _End label, and the
        # directive that emitted the bytes is the binclude before it.
        self.assertIn("binclude", listing.statement(0x240)[2])

    def test_declared_probes_name_files_that_exist(self) -> None:
        layout = json.loads((ROOT / "config/rom_layout.json").read_text(encoding="utf-8"))
        probe = layout["relocation_probe"]
        self.assertTrue(probe["probes"])
        for entry in probe["probes"]:
            returns = entry.get("return_filler")
            if returns:
                self.assertLessEqual(len(returns["skip_modules"]), returns["maximum_skipped_modules"])
                for module in returns["skip_modules"]:
                    self.assertTrue((ROOT / module).is_file(), module)
                self.assertTrue(returns["skip_reason"].strip())
                continue
            targets = entry.get("gap_growth", []) + entry.get("code_filler", [])
            self.assertTrue(targets, entry["id"])
            for target in targets:
                self.assertTrue((ROOT / target["file"]).is_file(), target["file"])
        for rule in probe["accepted_coincidences"]:
            self.assertRegex(rule["value"], r"^0x[0-9A-F]{6}$")
            self.assertTrue(rule["why"].strip())

    def test_a_branch_table_slot_is_not_a_return(self) -> None:
        table = [
            "                jmp     Dispatch(pc,d0.w)",
            "Dispatch:",
            "                rts",
            "                bra.s   Mode1",
        ]
        self.assertFalse(verify_relocation.returns_are_safe(table, 2))
        routine = ["                rts", "; End of function X", "NextRoutine:"]
        self.assertTrue(verify_relocation.returns_are_safe(routine, 0))
        self.assertTrue(verify_relocation.returns_are_safe(["                rts"], 0))

    def test_module_shifts_report_what_moved(self) -> None:
        before = [(0x100, "a.s"), (0x200, "b.s")]
        after = [(0x100, "a.s"), (0x400, "b.s")]
        rows = verify_relocation.module_shifts(_includes(before), _includes(after))
        self.assertEqual(0, verify_relocation.shift_at(rows, 0x180))
        self.assertEqual(0x200, verify_relocation.shift_at(rows, 0x300))
        self.assertIsNone(verify_relocation.shift_at(rows, 0x10))


class _includes:
    """A stand-in carrying only the include table compare() needs."""

    def __init__(self, includes: list[tuple[int, str]]) -> None:
        self.includes = includes


if __name__ == "__main__":
    unittest.main()
