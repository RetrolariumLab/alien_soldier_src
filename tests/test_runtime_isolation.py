from __future__ import annotations

import configparser
import copy
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import runtime_isolation as isolation  # noqa: E402


class PrivatePathTests(unittest.TestCase):
    def create(self, directory, **options):
        contents, record = isolation.isolated_config(Path(directory), **options)
        path = Path(directory) / "private.cfg"
        path.write_bytes(contents)
        return path, record

    def test_all_source_keys_have_absolute_private_trailing_separator_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            config, record = self.create(directory, sound=True, extra_sections={"Sound": {"Rate": 44100}})
            parsed = configparser.ConfigParser()
            parsed.read(config)
            self.assertEqual(set(isolation.PATH_KEYS), set(record["general_paths"]))
            self.assertEqual("1", parsed["Sound"]["State"])
            self.assertEqual("44100", parsed["Sound"]["Rate"])
            for key, value in record["general_paths"].items():
                self.assertTrue(Path(value).is_absolute())
                self.assertTrue(value.endswith(os.sep))
                self.assertEqual(value, parsed["General"][key])
                self.assertTrue(Path(value).is_relative_to(Path(directory)))
            isolation.validate_private_config(record, config)
            isolation.validate_isolation(record, startup="runtime")

    def test_unexpected_sidecar_is_rejected_before_and_after_process(self):
        for name in ("preservation.ips", "screen.pat", "audition.srm", "new.cfg"):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                _config, record = self.create(directory)
                (Path(record["sidecar_directory"]) / name).write_bytes(b"unsafe")
                for finished in (False, True):
                    with self.assertRaisesRegex(ValueError, "sidecar"):
                        isolation.validate_isolation(record, finished=finished)

    def test_startup_is_empty_before_use_but_only_native_outputs_are_accepted_after(self):
        with tempfile.TemporaryDirectory() as directory:
            _config, record = self.create(directory)
            startup = Path(record["startup_directories"]["runtime"])
            (startup / "Gens.cfg").write_text("owned native shutdown config")
            (startup / "language.dat").write_text("owned native language cache")
            with self.assertRaisesRegex(ValueError, "startup"):
                isolation.validate_isolation(record, startup="runtime")
            isolation.validate_isolation(record, startup="runtime", finished=True)
            (startup / "screen.ips").write_bytes(b"not a native output")
            with self.assertRaisesRegex(ValueError, "startup"):
                isolation.validate_isolation(record, startup="runtime", finished=True)

    def test_each_pass_has_a_distinct_unused_startup_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            _config, record = self.create(directory, startup_names=("discovery", "capture"))
            (Path(record["startup_directories"]["discovery"]) / "Gens.cfg").write_text("owned output")
            isolation.validate_isolation(record, startup="discovery", finished=True)
            isolation.validate_isolation(record, startup="capture")
            with self.assertRaisesRegex(ValueError, "unavailable"):
                isolation.validate_isolation(record, startup="absent")

    def test_changed_or_redirected_config_and_path_inventory_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            config, record = self.create(directory)
            config.write_bytes(config.read_bytes() + b"State=1\n")
            with self.assertRaisesRegex(ValueError, "config changed"):
                isolation.validate_private_config(record, config)
            changed = copy.deepcopy(record)
            changed["general_paths"]["IPS Patch path"] = str(ROOT) + os.sep
            with self.assertRaisesRegex(ValueError, "path inventory"):
                isolation.validate_isolation(changed)
            changed = copy.deepcopy(record)
            changed["startup_directories"]["runtime"] = str(ROOT)
            with self.assertRaisesRegex(ValueError, "redirected"):
                isolation.validate_isolation(changed)

    def test_existing_directory_or_ini_injection_never_overwrites_files(self):
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / "native-sidecars").mkdir()
            original = Path(directory) / "native-sidecars" / "kept.ips"
            original.write_bytes(b"keep")
            with self.assertRaises(FileExistsError):
                isolation.isolated_config(Path(directory))
            self.assertEqual(b"keep", original.read_bytes())
        for extra in (
            {"General": {"IPS Patch path": "outside"}},
            {"Sound": {"Rate": "44100\n[General]"}},
            {"Sound": {"state": 1}},
            {"Options": {"Auto Fix Checksum": 1}},
        ):
            with self.subTest(extra=extra), tempfile.TemporaryDirectory() as directory:
                with self.assertRaises(ValueError):
                    isolation.isolated_config(Path(directory), extra_sections=extra)

    def test_junction_and_symlink_paths_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with mock.patch.object(isolation, "_is_link", return_value=True):
                with self.assertRaisesRegex(ValueError, "filesystem link"):
                    isolation.isolated_config(Path(directory))


class NativeProofTests(unittest.TestCase):
    def test_contract_pins_real_path_readers_and_native_cwd_not_executable_path(self):
        checkout = ROOT / "build/runtime-emulator/pinned-e14b925"
        if not checkout.is_dir():
            self.skipTest("local clean pinned source checkout is unavailable")
        contract = isolation.native_config_contract(checkout)
        self.assertEqual(list(isolation.PATH_KEYS), contract["path_keys"])
        self.assertEqual("GetCurrentDirectory -> Gens_Path", contract["startup_directory_source"])
        self.assertEqual(set(isolation.NATIVE_FILES), set(contract["source_sha256"]))
        original_read = Path.read_text
        for name, old, new in (
            ("save.cpp", '"IPS Patch path"', '"Different IPS key"'),
            ("G_main.cpp", "GetCurrentDirectory(1024, Gens_Path)", "GetCurrentDirectory(1024, Different_Path)"),
            ("save.cpp", '"Auto Fix Checksum", 0', '"Auto Fix Checksum", 1'),
        ):

            def changed(path, *args, **kwargs):
                text = original_read(path, *args, **kwargs)
                return text.replace(old, new) if path.name == name else text

            with self.subTest(name=name, old=old), mock.patch.object(Path, "read_text", changed):
                with self.assertRaises(ValueError):
                    isolation.native_config_contract(checkout)


if __name__ == "__main__":
    unittest.main()
