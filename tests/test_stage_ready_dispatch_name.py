"""Keep the setup exit name bound to the real game-mode dispatcher."""

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class StageReadyDispatchNameTests(unittest.TestCase):
    def test_nonzero_setup_exit_selects_stage_ready_not_continue(self):
        source = (ROOT / "src/stages/gameplay_initialization.s").read_text(encoding="utf-8")
        name = "WeaponSetup_ExitToStageReady"
        self.assertNotIn("WeaponSetup_ExitToContinueScreen", source)
        self.assertRegex(source, r"bne\.s\s+" + name)
        body = source.split(name + ":", 1)[1].split("; End of function", 1)[0]
        self.assertIn("was: loc_1F11C", body)
        self.assertRegex(body, r"move\.w\s+#\$3C,\(GameModeIndex\)\.w")
        table = (ROOT / "src/system/vblank.s").read_text(encoding="utf-8").split(
            "Sys_GameStateHandlers:", 1)[1].split("; End of function", 1)[0]
        handlers = re.findall(r"\bdc\.l\s+(\w+)", table)
        self.assertEqual("StageReady_Initialize", handlers[0x3C // 4])
        document = json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))
        # The policy stores reviewed definitions in its records inventory.
        records = document["records"]
        record = next(item for item in records if item["current_name"] == name)
        self.assertEqual("loc_1F11C", record["legacy_name"])
        self.assertEqual("static", record["evidence"])
        self.assertTrue(any("StageReady_Initialize" in basis for basis in record["basis"]))


if __name__ == "__main__":
    unittest.main()
