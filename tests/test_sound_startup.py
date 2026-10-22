"""Owned sound startup ordering: real config bytes and native-source mutants."""

from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import sound_startup as startup  # noqa: E402
from runtime_isolation import isolated_config, validate_isolation  # noqa: E402


NATIVE_FIXTURE = {
    "src/G_main.cpp": """
Sound_Enable = 0; Sound_Initialised = 0;
strcpy(Str_Tmp,Gens_Path); strcat(Str_Tmp,"\\\\gens.cfg"); Load_Config(Str_Tmp,NULL);
if (!Init_Sound(hWnd)) { Sound_Enable=0; YM2612_Enable=0; PSG_Enable=0; DAC_Enable=0; }
Sound_Enable=1; Play_Sound();
int PASCAL WinMain()
{ Init(hInst, nCmdShow); ParseCmdLine(lpCmdLine, HWnd); }
""",
    "src/ParseCmdLine.cpp": """
if (found) { newCommand="argument"; } else newCommand="";
// Assignment switch is outside the argument-present branch.
switch (x) { case 15: //-nosound
Sound_Enable = 0; break; }
Load_Config((char*)CfgToLoad.c_str(), NULL);
GensLoadRom(RomToLoad.c_str());
""",
    "src/save.cpp": """
new_val = GetPrivateProfileInt("Sound", "State", 1, Conf_File);
if (new_val != Sound_Enable) { if (Change_Sound(HWnd)) { } }
""",
    "src/G_dsound.cpp": "if (Sound_Initialised) return 0; End_Sound();\n",
    "src/Gens.cpp": "if (Sound_Enable) { End_Sound(); if (!Init_Sound(HWnd)) Sound_Enable = 0; else Play_Sound(); }\n",
}


class SoundStartupTests(unittest.TestCase):
    def context(self, root, **options):
        data, isolation = isolated_config(
            root, sound=True, extra_sections={"Sound": {"Rate": "44100", "Stereo": "1", "PSG State": "1"}}, **options
        )
        config = root / "gens.cfg"
        config.write_bytes(data)
        return config, isolation

    def test_seed_changes_only_the_startup_sound_state(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config, isolation = self.context(root)
            original = config.read_bytes()
            record = startup.prepare(isolation, config)
            seed = (root / startup.SNAPSHOT).read_bytes()
            self.assertEqual(original.replace(startup.STATE_SITE, b"[Sound]\nState=0\n", 1), seed)
            self.assertEqual(original, config.read_bytes())
            self.assertEqual(hashlib.sha256(seed).hexdigest(), record["sha256"])
            self.assertEqual(seed, (Path(isolation["startup_directories"]["runtime"]) / "gens.cfg").read_bytes())
            startup.validate(record, isolation, config, launched=False)

    def test_default_isolation_policy_still_requires_empty_startup(self):
        with tempfile.TemporaryDirectory() as directory:
            config, isolation = self.context(Path(directory))
            startup.prepare(isolation, config)
            with self.assertRaisesRegex(ValueError, "startup"):
                validate_isolation(isolation)

    def test_native_shutdown_working_copy_is_an_output_not_an_immutable_input(self):
        with tempfile.TemporaryDirectory() as directory:
            config, isolation = self.context(Path(directory))
            record = startup.prepare(isolation, config)
            working = Path(isolation["startup_directories"]["runtime"]) / "gens.cfg"
            working.write_text("native shutdown config output", encoding="ascii")
            startup.validate(record, isolation, config, launched=True)
            with self.assertRaisesRegex(ValueError, "working copy"):
                startup.validate(record, isolation, config, launched=False)

    def test_extra_prelaunch_language_or_link_input_is_not_accepted(self):
        with tempfile.TemporaryDirectory() as directory:
            config, isolation = self.context(Path(directory))
            record = startup.prepare(isolation, config)
            (Path(isolation["startup_directories"]["runtime"]) / "language.dat").write_bytes(b"not yet native output")
            with self.assertRaisesRegex(ValueError, "prelaunch"):
                startup.validate(record, isolation, config, launched=False)

    def test_existing_seed_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config, isolation = self.context(root)
            path = root / startup.SNAPSHOT
            path.write_bytes(b"keep prior evidence")
            with self.assertRaisesRegex(ValueError, "overwrites"):
                startup.prepare(isolation, config)
            self.assertEqual(b"keep prior evidence", path.read_bytes())
            self.assertEqual([], list(Path(isolation["startup_directories"]["runtime"]).iterdir()))

    def test_zero_or_duplicate_state_sites_are_not_guessed(self):
        for data in (b"[Sound]\nState=0\n", startup.STATE_SITE * 2, b"[Sound]\r\nState=1\r\n", b"[sound]\nState=1\n"):
            with self.subTest(data=data), self.assertRaises(ValueError):
                startup.seed_bytes(data)

    def test_snapshot_config_and_seed_receipt_mutations_are_rejected(self):
        for kind in ("snapshot", "config", "hash", "owner", "profile"):
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                config, isolation = self.context(root)
                record = startup.prepare(isolation, config)
                if kind == "snapshot":
                    (root / startup.SNAPSHOT).write_bytes(b"changed seed")
                elif kind == "config":
                    config.write_bytes(config.read_bytes() + b";changed\n")
                elif kind == "hash":
                    record["sha256"] = "f" * 64
                elif kind == "owner":
                    record["startup"] = "outside"
                else:
                    record["explicit_config_sha256"] = "f" * 64
                with self.assertRaises(ValueError):
                    startup.validate(record, isolation, config, launched=True)

    def test_exact_seed_record_types_and_inventory_are_required(self):
        with tempfile.TemporaryDirectory() as directory:
            config, isolation = self.context(Path(directory))
            record = startup.prepare(isolation, config)
            for field, value in (
                ("schema_version", True),
                ("startup", []),
                ("snapshot", "../outside.ini"),
                ("working", "other.cfg"),
                ("scope", "audio_fidelity"),
                ("extra", 1),
            ):
                mutant = dict(record, **{field: value})
                with self.subTest(field=field), self.assertRaises(ValueError):
                    startup.validate(mutant, isolation, config, launched=True)
            with self.assertRaises(ValueError):
                startup.validate(record, isolation, config, launched=1)

    def test_another_pass_stays_unused_and_cannot_take_this_seed(self):
        with tempfile.TemporaryDirectory() as directory:
            config, isolation = self.context(Path(directory), startup_names=("discovery", "capture"))
            record = startup.prepare(isolation, config, startup="discovery")
            validate_isolation(isolation, startup="capture")
            record["startup"] = "capture"
            with self.assertRaisesRegex(ValueError, "working copy"):
                startup.validate(record, isolation, config, launched=False)

    def test_sidecar_and_path_escapes_still_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config, isolation = self.context(root)
            (Path(isolation["sidecar_directory"]) / "injected.ips").write_bytes(b"PATCH")
            with self.assertRaisesRegex(ValueError, "sidecar"):
                startup.prepare(isolation, config)
            self.assertFalse((root / startup.SNAPSHOT).exists())
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config, isolation = self.context(root)
            record = startup.prepare(isolation, config)
            with self.assertRaisesRegex(ValueError, "escapes"):
                startup.validate(record, isolation, root.parent / "outside.cfg", launched=True)

    def test_linked_snapshot_is_not_followed(self):
        with tempfile.TemporaryDirectory() as directory:
            config, isolation = self.context(Path(directory))
            record = startup.prepare(isolation, config)
            with mock.patch.object(
                Path, "is_symlink", autospec=True, side_effect=lambda path: path.name == startup.SNAPSHOT
            ):
                with self.assertRaises(ValueError):
                    startup.validate(record, isolation, config, launched=True)


class SoundStartupSourceTests(unittest.TestCase):
    def fixture(self, root, texts=NATIVE_FIXTURE):
        for name, text in texts.items():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")

    def test_complete_chain_binds_all_actual_source_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fixture(root)
            proof = startup.native_contract(root)
            self.assertEqual(startup.SCOPE, proof["scope"])
            self.assertEqual(set(startup.NATIVE_FILES), set(proof["source_sha256"]))
            self.assertEqual(
                {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in startup.NATIVE_FILES},
                proof["source_sha256"],
            )

    def test_each_native_chain_step_and_order_mutation_fails(self):
        cases = (
            (
                "src/G_main.cpp",
                "Init(hInst, nCmdShow); ParseCmdLine(lpCmdLine, HWnd);",
                "ParseCmdLine(lpCmdLine, HWnd); Init(hInst, nCmdShow);",
            ),
            ("src/ParseCmdLine.cpp", 'else newCommand="";', 'else { newCommand=""; }'),
            ("src/ParseCmdLine.cpp", "case 15:", "case 16:"),
            ("src/save.cpp", "new_val != Sound_Enable", "new_val == Sound_Enable"),
            ("src/G_dsound.cpp", "if (Sound_Initialised) return 0;", "if (Sound_Initialised) return 1;"),
            ("src/Gens.cpp", "End_Sound();", "Skip_End_Sound();"),
        )
        for name, before, after in cases:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                texts = dict(NATIVE_FIXTURE)
                self.assertIn(before, texts[name])
                texts[name] = texts[name].replace(before, after)
                root = Path(directory)
                self.fixture(root, texts)
                with self.assertRaises((ValueError, IndexError)):
                    startup.native_contract(root)

    def test_actual_pin_proof_is_read_only_and_optional_without_a_checkout(self):
        checkout = ROOT / "build/runtime-emulator/pinned-e14b925"
        if not checkout.is_dir():
            self.skipTest("optional pinned native source; production Make gate requires it")
        proof = startup.native_contract(checkout)
        self.assertEqual(set(startup.NATIVE_FILES), set(proof["source_sha256"]))


if __name__ == "__main__":
    unittest.main()
