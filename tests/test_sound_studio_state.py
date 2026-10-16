from __future__ import annotations

from copy import deepcopy
import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_studio import load_context, parse_value, replacement_for  # noqa: E402
from authoring.sound_studio_state import Workspace  # noqa: E402
from authoring.sound_instrument_model import decode_instrument  # noqa: E402
from authoring.sound_studio_model import decode_instruction  # noqa: E402


def tiny_documents() -> dict:
    """Fresh reader-shaped editor inputs, not a source/model qualification.

    Exercise every special hidden sequence operand, both pan-animation forms,
    and immutable header fields without exporting 33,062 real instructions.
    The three genuine corpus methods below still load the actual documents.
    """
    body = bytes.fromhex("05 8106 E101 E400 E40102030405 FF0103 F60000 F700010000 F80000")
    instructions, cursor = [], 0
    while cursor < len(body):
        instruction = decode_instruction("fixture", body, cursor)
        instruction["data"] = list(body[cursor:cursor + instruction["size"]])
        # Place the independently decoded event examples after a ten-byte
        # header. This fixture tests exposed fields, not reachable execution.
        instruction["offset"] += 10
        if "target" in instruction:
            instruction["target"] += 10
        instructions.append(instruction)
        cursor += instruction["size"]
    return {
        "sound_envelopes": {"families": [{"id": "pitch", "blocks": [{
            "name": "fixture", "values": [{"offset": 0, "value": 0},
                {"offset": 1, "value": -1}, {"offset": 2, "value": 2}],
            "commands": [{"offset": 3, "opcode": 0x81}],
        }]}]},
        "sound_instruments": {"payloads": [{"name": "fixture",
            "header_byte_count": 10, "instrument_offset": 40,
            "instruments": [decode_instrument(0, bytes(25))]}]},
        "sound_pcm_samples": {"banks": [{"name": "fixture", "samples": [{
            "index": 0, "header_offset": 8, "start_offset": 16,
            "byte_count": 2, "data": "A3B3", "header_words": [16, 2, 0],
        }]}]},
        "sound_sequences": {"payloads": [{"name": "fixture", "family": "bgm",
            "header_byte_count": 10, "instrument_offset": 40,
            "entry_offsets": [10], "instructions": instructions}]},
    }


class SoundStudioStateTests(unittest.TestCase):
    def setUp(self) -> None:
        self._state = None
        self.context_loads = 0

    @property
    def state(self):
        if self._state is None:
            context = load_context(ROOT, "jp")
            self.context_loads += 1
            self._state = Workspace({
                identifier: record["document"] for identifier, record in context.items()
            })
        return self._state

    def test_every_manifest_artifact_has_editable_fields(self) -> None:
        self.assertEqual(
            {
                "sound_envelopes", "sound_instruments", "sound_pcm_samples",
                "sound_sequences",
            },
            set(self.state.artifact_ids),
        )
        for identifier in self.state.artifact_ids:
            self.state.select_artifact(identifier)
            self.assertGreater(len(self.state.artifact_fields), 0)
            self.assertGreater(self.state.field.length, 0)

    def test_edit_marks_only_selected_artifact_dirty(self) -> None:
        documents = tiny_documents()
        original = deepcopy(documents)
        self._state = Workspace(documents)
        self.state.select_artifact("sound_instruments")
        before = self.state.value
        replacement = replacement_for(before, self.state.bounds)
        self.state.set_value(replacement)
        self.assertEqual({"sound_instruments"}, self.state.dirty)
        self.assertEqual(replacement, self.state.value)
        for identifier in documents.keys() - {"sound_instruments"}:
            self.assertEqual(documents[identifier], original[identifier])

        # Use an independent fresh editor to check that all hidden sequence
        # roles survive actual editable operand changes, not a mocked mapper.
        probe = Workspace(tiny_documents())
        probe.select_artifact("sound_sequences")
        payload = probe.documents["sound_sequences"]["payloads"][0]
        before = deepcopy(payload)
        exposed = {(value.container["offset"], value.index)
                   for field in probe.artifact_fields for value in field.values}
        self.assertEqual({item["opcode"] for item in payload["instructions"]
                          if item["kind"] == "command"}, {0xE1, 0xE4, 0xFF, 0xF6, 0xF7, 0xF8})
        for item in payload["instructions"]:
            if item["kind"] != "command":
                continue
            self.assertNotIn((item["offset"], 0), exposed)
            if item["opcode"] in (0xE4, 0xFF):
                self.assertNotIn((item["offset"], 1), exposed)
            if item["opcode"] in (0xF6, 0xF7, 0xF8):
                self.assertFalse(any(offset == item["offset"] for offset, _index in exposed))
        for index in range(probe.field.length):
            probe.select_value(index)
            probe.set_value(replacement_for(probe.value, probe.bounds))
        self.assertEqual({"sound_sequences"}, probe.dirty)
        for old, changed in zip(before["instructions"], payload["instructions"], strict=True):
            for index, value in enumerate(old["data"]):
                if (old["offset"], index) not in exposed:
                    self.assertEqual(changed["data"][index], value)
        for key in ("header_byte_count", "instrument_offset", "entry_offsets"):
            self.assertEqual(payload[key], before[key])

        pcm = Workspace(tiny_documents())
        pcm.select_artifact("sound_pcm_samples")
        sample = pcm.field.values[0].container
        metadata = {key: deepcopy(value) for key, value in sample.items() if key != "data"}
        pcm.set_value(replacement_for(pcm.value, pcm.bounds))
        self.assertEqual({key: value for key, value in sample.items() if key != "data"}, metadata)
        self.assertEqual(len(sample["data"]), metadata["byte_count"] * 2)
        self.assertEqual(tiny_documents(), original)
        self.assertEqual(self.context_loads, 0)

    def test_sequence_control_flow_and_opcodes_are_not_exposed(self) -> None:
        self.state.select_artifact("sound_sequences")
        for field in self.state.artifact_fields:
            for value in field.values:
                instruction = value.container
                if instruction["kind"] != "command":
                    continue
                self.assertNotEqual(0, value.index)
                self.assertNotIn(instruction.get("opcode"), (0xF6, 0xF7, 0xF8))
                if instruction.get("opcode") == 0xFF:
                    self.assertNotEqual(1, value.index)
                if instruction.get("opcode") == 0xE4:
                    self.assertNotEqual(1, value.index)

    def test_envelope_commands_and_pcm_structure_are_not_exposed(self) -> None:
        self.state.select_artifact("sound_envelopes")
        self.assertTrue(all(
            set(value.container) == {"offset", "value"}
            for field in self.state.artifact_fields for value in field.values
        ))

        self.state.select_artifact("sound_pcm_samples")
        sample = self.state.field.values[0].container
        before = sample["data"]
        header = sample["header_offset"]
        self.state.set_value(replacement_for(self.state.value, self.state.bounds))
        self.assertEqual(header, sample["header_offset"])
        self.assertEqual(len(before), len(sample["data"]))
        self.assertNotEqual(before, sample["data"])

    def test_signed_bounds_and_window_are_explicit(self) -> None:
        self._state = Workspace(tiny_documents())
        self.state.select_artifact("sound_envelopes")
        self.assertEqual((-128, 127), self.state.bounds)
        with self.assertRaisesRegex(ValueError, "between -128 and 127"):
            self.state.set_value(128)
        start, values = self.state.visible_values(radius=2)
        self.assertEqual(0, start)
        self.assertLessEqual(len(values), 3)
        self.assertEqual(self.context_loads, 0)

    def test_workstation_numeric_parser_is_explicit(self) -> None:
        self.assertEqual(0x2A, parse_value("$2A"))
        self.assertEqual(0x2A, parse_value("0x2a"))
        self.assertEqual(42, parse_value("42"))
        self.assertEqual(-2, parse_value("-2"))
        self.assertIsNone(self._state)
        self.assertEqual(self.context_loads, 0)

    def test_manifest_publishes_the_workstation_contract(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        studio = next(item for item in document["studios"] if item["id"] == "sound")
        self.assertEqual("check-sound-workspace", studio["workspace_gate"])
        self.assertEqual("check-sound-studio", studio["workstation_gate"])
        self.assertEqual(
            ["save", "reload", "build", "dirty-close"],
            studio["workstation_actions"],
        )
        self.assertIsNone(self._state)
        self.assertEqual(self.context_loads, 0)


if __name__ == "__main__":
    unittest.main()
