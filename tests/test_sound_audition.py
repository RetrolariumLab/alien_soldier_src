"""Bounded request, exact loader-state, and owned-process audition tests."""

from __future__ import annotations

import copy
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import sound_audition as audition  # noqa: E402
from authoring import sound_audition_model as model  # noqa: E402
from authoring.sound_studio_model import BGM_REQUEST_IDS, SFX_REQUEST_IDS  # noqa: E402


RAM = {
    "GameModeIndex": 0xFFA284,
    "GameSubstateIndex": 0xFFA286,
    "SoundRequestQueue": 0xFFF80A,
    "SoundSelectedRequest": 0xFFF809,
    "SoundCurrentPriority": 0xFFF800,
    "SoundTempoReload": 0xFFF802,
    "SoundBGMDataPtr": 0xFFF820,
    "SoundPCMChannelRecord": 0xFFF840,
    "SoundBGMPSGChannels": 0xFFF990,
    "SoundSpecialSFXDataPtr": 0xFFF824,
    "SoundSpecialSFXFM": 0xFFFB40,
    "SoundSpecialSFXPSG": 0xFFFB70,
    "PaletteFadeMaskStatus": 0xFF80F4,
    "ScenePaletteFadeOffset": 0xFF0176,
    "DataLoaderControl": 0xFFF720,
}
SFX_POINTERS = [0xFFFFFA20, 0, 0xFFFFFA50, 0xFFFFFA80, 0xFFFFFAB0, 0xFFFFFAE0, 0xFFFFFB10, 0xFFFFFB10]
BGM = bytes([0, 20, 1, 1, 2, 7, 0, 16, 0x12, 0x34, 0, 18, 0x56, 0x78, 2, 3, 0x80, 1, 0xF2, 0])
SFX = bytes([0, 14, 1, 1, 0x80, 4, 0, 10, 0, 5, 0x80, 1, 0xF2, 0])


class RequestAndLoaderTests(unittest.TestCase):
    def test_every_source_payload_has_a_request_and_aliases_are_explicit(self):
        names = {model.payload_for_request(request) for request in BGM_REQUEST_IDS + SFX_REQUEST_IDS}
        self.assertEqual(182, len(names))
        for name in names:
            self.assertEqual(name, model.payload_for_request(model.request_for_payload(name)))
        self.assertEqual("Sound_BGM_81", model.payload_for_request(0x99))
        self.assertEqual(0x81, model.request_for_payload("Sound_BGM_81"))
        for value in (0, 4, 0x80, 0xFD, True):
            with self.subTest(request=value), self.assertRaises(ValueError):
                model.payload_for_request(value)

    def test_bgm_expectations_include_distinct_dac_and_psg_slots(self):
        hook, checks = model.loader_expectations(0x81, BGM, 0x1000, RAM, SFX_POINTERS)
        values = {item["name"]: item for item in checks}
        self.assertEqual("Sound_FinishBGMInitialization", hook)
        self.assertEqual(0x1014, values["bgm_instrument_pointer"]["value"])
        self.assertEqual(0xFFF844, values["channel_0_sequence_pointer"]["address"])
        self.assertEqual(0x1010, values["channel_0_sequence_pointer"]["value"])
        self.assertEqual(0xFFF994, values["channel_1_sequence_pointer"]["address"])
        self.assertEqual(0x1012, values["channel_1_sequence_pointer"]["value"])
        self.assertEqual(2, values["channel_1_pitch_selector"]["value"])
        self.assertEqual(3, values["channel_1_volume_selector"]["value"])

    def test_ordinary_and_special_sfx_use_their_actual_distinct_records(self):
        for request, record, hook in (
            (0xA0, 0xFFFA50, "Sound_LoadSFXReturn"),
            (0xF9, 0xFFFB40, "Sound_LoadSpecialSFXReturn"),
        ):
            with self.subTest(request=request):
                actual_hook, checks = model.loader_expectations(request, SFX, 0x1000, RAM, SFX_POINTERS)
                values = {item["name"]: item for item in checks}
                self.assertEqual(hook, actual_hook)
                self.assertEqual(record + 4, values["channel_0_sequence_pointer"]["address"])
                self.assertEqual(0x100A, values["channel_0_sequence_pointer"]["value"])
                if request < 0xF9:
                    self.assertEqual(record + 0x20, values["channel_0_instrument_pointer"]["address"])
                else:
                    self.assertEqual(0x100E, values["special_instrument_pointer"]["value"])

    def test_current_loader_contract_and_all_payload_headers_are_supported(self):
        model.source_contract(ROOT)
        for request in BGM_REQUEST_IDS + SFX_REQUEST_IDS:
            with self.subTest(request=request):
                body = model.payload_body(ROOT, model.payload_for_request(request))
                _hook, checks = model.loader_expectations(request, body, 0x1000, RAM, SFX_POINTERS)
                self.assertTrue(checks)


class ContractBindingTests(unittest.TestCase):
    def fixture(self, root: Path):
        symbols = {name: 0x700 + index * 0x40 for index, name in enumerate(model.ROM_NAMES)}
        symbols.update(RAM)
        symbols.update(
            {
                "Sound_LoadBGMRequest": 0x100,
                "Sound_StopSFXAndRestoreBGMChannels": 0x300,
                "Sound_SelectPendingRequest": 0x400,
                "Sound_ValidateVoiceDACRequest": 0x500,
                "Sound_DispatchPendingRequest": 0x420,
                "Sound_FinishBGMInitialization": 0x120,
                "Sound_BGM_81": 0x1600,
            }
        )
        image = bytearray(0x2000)
        image[0x120:0x124] = b"\x58\x4f\x4e\x75"
        image[0x420:0x422] = b"\x7e\x00"
        image[0x1600 : 0x1600 + len(BGM)] = BGM
        image[symbols["Sound_BGMPointerTable"] : symbols["Sound_BGMPointerTable"] + 4] = (0x1600).to_bytes(4, "big")
        at = symbols["Sound_SFXChannelRecordPointers"]
        for index, value in enumerate(SFX_POINTERS):
            image[at + index * 4 : at + index * 4 + 4] = value.to_bytes(4, "big")
        listing = root / "sound.lst"
        lines = []
        for name, address in symbols.items():
            head = "(1)    1/%8X :" % address
            source = name + ":" if name not in RAM else name + " equ $%X" % address
            lines.append(head.ljust(40) + source)
        listing.write_text("\n".join(lines), encoding="ascii")
        return image, symbols, listing

    def test_selected_source_bytes_pointer_and_loader_bind_listing_to_rom(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            image, _symbols, listing = self.fixture(root)
            with (
                mock.patch.object(model, "source_contract"),
                mock.patch.object(model, "payload_body", return_value=BGM),
            ):
                contract = model.build_contract(root, root, "jp", 0x81, image, image, listing)
                self.assertEqual(0x120, contract["hook_address"])
                for mutation, expected in (
                    ("payload", "selected staged"),
                    ("pointer", "request pointer"),
                    ("loader", "loader/dispatcher"),
                ):
                    changed = bytearray(image)
                    position = (
                        0x1600
                        if mutation == "payload"
                        else (_symbols["Sound_BGMPointerTable"] if mutation == "pointer" else 0x110)
                    )
                    changed[position] ^= 1
                    with self.subTest(mutation=mutation), self.assertRaisesRegex(ValueError, expected):
                        model.build_contract(root, root, "jp", 0x81, changed, image, listing)

    def test_listing_missing_or_conflicting_symbol_fails_before_any_launch(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _image, symbols, listing = self.fixture(root)
            with self.assertRaisesRegex(ValueError, "missing"):
                model.listing_symbols(listing, {"absent"})
            with listing.open("a", encoding="ascii") as stream:
                stream.write("\n" + "(1)    1/    1234 :".ljust(40) + "Sound_BGM_81:\n")
            with self.assertRaisesRegex(ValueError, "conflicting"):
                model.listing_symbols(listing, set(symbols))


class ReportAndLifecycleTests(unittest.TestCase):
    def contract(self):
        return {
            "profile": "eu",
            "request_id": 0xF9,
            "rom_sha256": "a" * 64,
            "checks": [{"name": "channel_0_sequence_pointer", "address": 0xFFFB44, "size": 4, "value": 0x123456}],
        }

    def report(self):
        return {
            "status": "loaded",
            "profile": "eu",
            "request_id": 0xF9,
            "rom_sha256": "a" * 64,
            "frame": 123,
            "observations": [0x123456],
        }

    def test_report_requires_exact_request_rom_and_each_observed_ram_value(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "result.json"
            report = self.report()
            path.write_text(json.dumps(report), encoding="utf-8")
            self.assertEqual(report, audition.parse_result(path, self.contract()))
            for key, value in (
                ("profile", "jp"),
                ("request_id", 0xFA),
                ("rom_sha256", "b" * 64),
                ("frame", True),
                ("observations", [0x123457]),
                ("observations", [True]),
            ):
                changed = copy.deepcopy(report)
                changed[key] = value
                path.write_text(json.dumps(changed), encoding="utf-8")
                with self.subTest(key=key), self.assertRaises(RuntimeError):
                    audition.parse_result(path, self.contract())

    def test_launch_has_sound_enabled_and_finite_frame_limit(self):
        command = audition.audition_command(Path("Gens.exe"), Path("rom.bin"), Path("private.cfg"), 120)
        self.assertIn("-cfg", command)
        self.assertNotIn("-nosound", command)
        self.assertNotIn("-turbo", command)
        self.assertEqual(str(audition.MAX_BOOT_FRAMES + 124), command[-1])

    def test_lua_story_start_pulse_uses_all_guard_symbols_and_releases_before_title(self):
        rendered = audition.lua_contract(
            {
                "hook_address": 0x200,
                "dispatch_hook_address": 0x180,
                "ram": RAM,
                "checks": [],
            }
        ).decode("ascii")
        script = audition.SCRIPT.read_text(encoding="utf-8")
        for name in ("PaletteFadeMaskStatus", "ScenePaletteFadeOffset", "DataLoaderControl"):
            self.assertIn("%s = %d" % (name, RAM[name]), rendered)
        pulse = script.split('if phase == "title" and mode == 0x0028', 1)[1].split(
            'elseif phase == "title" and mode == 0x0018', 1
        )[0]
        for gate in (
            "not story_skip_sent",
            "ram.PaletteFadeMaskStatus) % 2 == 1",
            "ram.ScenePaletteFadeOffset) == 0",
            "ram.DataLoaderControl) < 0x8000",
        ):
            self.assertIn(gate, pulse)
        self.assertIn("joypad.set(1, {start=true})", pulse)
        self.assertEqual(1, script.count("joypad.set(1, {start=true})"))
        frame_loop = script.split("for frame = 1, 1800 do", 1)[1]
        self.assertLess(frame_loop.index("joypad.set(1, {start=false})"), frame_loop.index("mode == 0x0018"))
        self.assertNotIn("{Start=true}", script)

    def test_invalid_rom_fails_before_creating_outputs_or_launching(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            gens = root / "Gens.exe"
            gens.touch()
            with (
                mock.patch.object(audition, "validate_playtest_rom", side_effect=ValueError("wrong profile")),
                mock.patch.object(audition.subprocess, "Popen") as spawn,
            ):
                with self.assertRaisesRegex(ValueError, "wrong profile"):
                    audition.launch(root, "eu", 0x81, root / "rom.bin", root / "sound.lst", gens)
                spawn.assert_not_called()
            self.assertFalse((root / "build").exists())

    def test_rendered_contract_and_private_config_cover_the_lua_launch_protocol(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            gens = root / "Gens.exe"
            gens.write_bytes(b"not launched")
            contract = self.contract() | {
                "schema_version": 1,
                "payload": "Sound_SFX_F9",
                "ram": RAM,
                "hook_address": 0x200,
                "dispatch_hook_address": 0x180,
                "hook_symbol": "Sound_LoadSpecialSFXReturn",
                "listing_sha256": "b" * 64,
                "rom_sha256": hashlib.sha256(b"rom").hexdigest(),
            }
            with (
                mock.patch.object(audition, "validate_playtest_rom", return_value=contract["rom_sha256"]),
                mock.patch.object(audition, "validate_reference", return_value=b"original"),
                mock.patch.object(
                    audition, "select_profile", return_value={"reference_rom": {"filename": "original.bin"}}
                ),
                mock.patch.object(audition, "build_contract", return_value=contract),
                mock.patch.object(audition, "environment_identity", return_value={"executable_path": str(gens)}),
                mock.patch.object(audition.sound_startup, "native_contract", return_value={"scope": "source-fixture"}),
                mock.patch.object(audition.subprocess, "Popen") as spawn,
            ):
                (root / "rom.bin").write_bytes(b"rom")
                session = audition.launch(root, "eu", 0xF9, root / "rom.bin", root / "sound.lst", gens, check=True)
            environment = spawn.call_args.kwargs["env"]
            lua = Path(environment["ALIEN_SOUND_CONTRACT"]).read_text(encoding="ascii")
            consumer = audition.SCRIPT.read_text(encoding="utf-8")
            for field in set(re.findall(r"contract\.([A-Za-z_][A-Za-z_0-9]*)", consumer)):
                self.assertRegex(lua, r"\b" + field + r"\s*=")
            self.assertIn("dispatch_hook = 384", lua)
            config = (session.directory / "gens.cfg").read_text(encoding="ascii")
            self.assertIn("[Sound]\nState=1", config)
            self.assertIn("PSG State=1", config)
            self.assertIn("Master Volume=0", config)
            self.assertIn("[General]", config)
            self.assertEqual(
                Path(session.contract["native_isolation"]["startup_directories"]["runtime"]),
                spawn.call_args.kwargs["cwd"],
            )
            self.assertNotEqual(gens.parent, spawn.call_args.kwargs["cwd"])
            startup = spawn.call_args.kwargs["cwd"] / "gens.cfg"
            self.assertIn(b"[Sound]\nState=0\n", startup.read_bytes())
            self.assertEqual(startup.read_bytes(), (session.directory / "sound-startup-seed.ini").read_bytes())
            audition.sound_startup.validate(
                session.contract["sound_startup"],
                session.contract["native_isolation"],
                session.directory / "gens.cfg",
                launched=False,
            )
            self.assertEqual("1", environment["ALIEN_SOUND_CHECK"])
            command = spawn.call_args.args[0]
            launched_rom = Path(command[command.index("-rom") + 1])
            self.assertEqual(session.directory, launched_rom.parent)
            self.assertEqual(b"rom", launched_rom.read_bytes())
            receipt = json.loads((session.directory / "contract.json").read_text(encoding="utf-8"))
            self.assertRegex(receipt["gens_sha256"], r"^[0-9a-f]{64}$")
            if os.name == "nt":
                startupinfo = spawn.call_args.kwargs["startupinfo"]
                self.assertTrue(startupinfo.dwFlags & subprocess.STARTF_USESHOWWINDOW)
                self.assertEqual(0, startupinfo.wShowWindow)

    def test_native_contract_change_private_config_or_sidecar_refuses_completion(self):
        from runtime_isolation import isolated_config

        for mutation in ("native", "config", "sidecar", "rom"):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                config, record = isolated_config(root, sound=True)
                (root / "gens.cfg").write_bytes(config)
                (root / "audition.bin").write_bytes(b"rom")
                native = {"executable_path": str(root / "Gens.exe"), "identity": "original"}
                contract = self.contract() | {
                    "runtime_environment": native,
                    "native_isolation": record,
                    "rom_sha256": hashlib.sha256(b"rom").hexdigest(),
                }
                process = mock.Mock()
                process.poll.return_value = 0
                session = audition.Session(
                    process, contract, root / "result.json", root / "stop.txt", root, ready=self.report(), root=root
                )
                current = native.copy()
                if mutation == "native":
                    current["identity"] = "changed"
                elif mutation == "config":
                    (root / "gens.cfg").write_bytes(config + b"; changed\n")
                elif mutation == "sidecar":
                    (Path(record["sidecar_directory"]) / "audition.ips").write_bytes(b"PATCH")
                else:
                    (root / "audition.bin").write_bytes(b"bad")
                with mock.patch.object(audition, "environment_identity", return_value=current):
                    with self.assertRaises((RuntimeError, ValueError)):
                        session.poll()

    def test_stopping_live_owned_process_queues_graceful_stop_then_reaps(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            process = mock.Mock()
            process.poll.return_value = None
            process.wait.side_effect = subprocess.TimeoutExpired("gens", 1)
            session = audition.Session(process, self.contract(), root / "result.json", root / "stop.txt", root)
            with mock.patch.object(audition, "stop_process") as stop:
                session.stop()
                stop.assert_called_once_with(process)
            self.assertEqual(b"stop\n", session.stop_file.read_bytes())

    def test_seed_source_or_helper_change_refuses_native_session_completion(self):
        from runtime_isolation import isolated_config

        for mutation in ("snapshot", "source", "helper"):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                config, isolation = isolated_config(root, sound=True)
                path = root / "gens.cfg"
                path.write_bytes(config)
                seed = audition.sound_startup.prepare(isolation, path)
                (root / "audition.bin").write_bytes(b"rom")
                (root / "contract.lua").write_bytes(b"return {}\n")
                native = {"executable_path": str(root / "Gens.exe"), "identity": "fixed fixture"}
                source = {"scope": "source fixture"}
                contract = self.contract() | {
                    "runtime_environment": native,
                    "native_isolation": isolation,
                    "sound_startup": seed,
                    "sound_startup_source": source,
                    "sound_startup_module_sha256": audition.digest_file(Path(audition.sound_startup.__file__)),
                    "rom_sha256": hashlib.sha256(b"rom").hexdigest(),
                    "runner_sha256": audition.digest_file(Path(audition.__file__)),
                    "lua_sha256": audition.digest_file(audition.SCRIPT),
                    "generated_contract_sha256": audition.digest_file(root / "contract.lua"),
                }
                current = source.copy()
                if mutation == "snapshot":
                    (root / "sound-startup-seed.ini").write_bytes(b"changed")
                elif mutation == "source":
                    current["scope"] = "changed fixture"
                else:
                    contract["sound_startup_module_sha256"] = "0" * 64
                process = mock.Mock()
                process.poll.return_value = 0
                session = audition.Session(
                    process,
                    contract,
                    root / "result.json",
                    root / "stop.txt",
                    root,
                    ready=self.report() | {"rom_sha256": contract["rom_sha256"]},
                    root=root,
                )
                with (
                    mock.patch.object(audition, "environment_identity", return_value=native),
                    mock.patch.object(audition.sound_startup, "native_contract", return_value=current),
                    self.assertRaises((RuntimeError, ValueError)),
                ):
                    session.poll()

    def test_failed_report_surfaces_the_separate_diagnostic_without_accepting_it(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            result = root / "result.json"
            result.write_text(json.dumps(self.report() | {"status": "timeout", "observations": []}), encoding="utf-8")
            diagnostic = result.with_name(result.name + ".diagnostic.json")
            evidence = b'{"phase":"stopping","queue":[0,0,0,0],"loader_hook_count":0}\n'
            diagnostic.write_bytes(evidence)
            process = mock.Mock()
            process.poll.return_value = None
            session = audition.Session(process, self.contract(), result, root / "stop.txt", root)
            with self.assertRaisesRegex(RuntimeError, "diagnostic:") as failure:
                session.poll()
            self.assertIn(str(diagnostic), str(failure.exception))
            self.assertIsNone(session.ready)
            self.assertEqual(evidence, diagnostic.read_bytes())


if __name__ == "__main__":
    unittest.main()
