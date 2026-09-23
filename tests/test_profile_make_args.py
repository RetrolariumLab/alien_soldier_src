"""Bounded Make dry-runs/stub calls; no AS, p2bin, native game or ROM output."""
from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
import hashlib
import io
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import runpy

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from check_profile_as_args import validate_flags
from authoring.build_content import assembler_args
from authoring.atomic_output import atomic_write_bytes, atomic_write_json
import init_project

FIXTURE = ROOT / "tests/fixtures/profile_flags_terminal.py"
OUTPUTS = ROOT / "build/content/profile-flags"


class InitForwarding(unittest.TestCase):
    def virtual_init(self, flags):
        captured = []
        argv = ["init_project.py", "--orig-rom", "virtual-original", "--manifest", "virtual-manifest",
                "--data-dir", "virtual-data", "--data-addrs", "virtual-addrs", "--source", "virtual-source",
                "--obj", "virtual-object", "--output", "virtual-output", "--as-bin", "never-AS",
                "--p2bin", "never-p2bin", "--as-args=" + flags]
        def virtual_open(path, mode="r", **_kwargs):
            if path == "virtual-original" and mode == "rb":
                return io.BytesIO(b"")
            if path == "virtual-manifest":
                return io.StringIO(json.dumps({"reference_rom": {"size": 0, "sha1": hashlib.sha1(b"").hexdigest()}}))
            raise AssertionError("unexpected real file open: " + str(path))
        def terminal(command):
            captured.append(command)
            return mock.Mock(returncode=0)
        actual_exists = os.path.exists
        with (mock.patch.object(sys, "argv", argv), mock.patch.object(init_project.os.path, "exists", side_effect=lambda path: path == "virtual-original" or actual_exists(path)),
              mock.patch("builtins.open", side_effect=virtual_open), mock.patch.object(init_project.subprocess, "run", side_effect=terminal),
              redirect_stdout(io.StringIO())):
            self.assertEqual(0, init_project.main())
        self.assertEqual(3, len(captured))
        return captured[-1]

    def test_init_forwards_one_assignment_argv_for_default_custom_and_dash_only(self):
        for flags in ("-maxerrors 2", "-q", "-q -maxerrors 2 -D BuildProfileEU=1"):
            with self.subTest(flags=flags):
                command = self.virtual_init(flags)
                self.assertIn("--as-args=" + flags, command)
                self.assertNotIn("--as-args", command)

    def test_real_build_rom_parser_accepts_forwarded_dash_only_without_any_assembly(self):
        command = self.virtual_init("-q")
        output, errors = io.StringIO(), io.StringIO()
        # The actual CLI parses successfully, then terminates on a deliberately
        # unsupported IN-MEMORY manifest before assemble_main_src can run.
        with (mock.patch.object(sys, "argv", command[1:]),
              mock.patch("builtins.open", return_value=io.StringIO('{"schema_version":0}')),
              mock.patch("platform.system", return_value="Windows"),
              mock.patch("platform.machine", return_value="i386"),
              mock.patch.object(subprocess, "call") as assembler,
              mock.patch.object(subprocess, "Popen") as converter,
              redirect_stdout(output), redirect_stderr(errors)):
            with self.assertRaises(SystemExit) as stopped:
                runpy.run_path(str(ROOT / "scripts/build_rom.py"), run_name="__main__")
        self.assertEqual(1, stopped.exception.code)
        self.assertIn("Unsupported asset manifest schema", output.getvalue())
        self.assertEqual("", errors.getvalue())
        assembler.assert_not_called()
        converter.assert_not_called()


class FlagValidation(unittest.TestCase):
    def test_ordinary_flags_and_unrelated_defines_are_allowed(self):
        for flags in ("", "-q", "-q -maxerrors 2", '-D MyFeature=1 -q', '-DMyFeature=0', '-d "Other=2"'):
            with self.subTest(flags=flags):
                validate_flags(flags)

    def test_reserved_defines_fail_in_separated_attached_quoted_and_casefold_forms(self):
        for flags in ('-D BuildProfileEU=0', '-DBuildProfileEU=1', '-dBuildProfileJP=1', '-D "bUiLdPrOfIlEeU=1"', '-d buildprofilejp', '-D BUILDPROFILEEU=0 -q'):
            with self.subTest(flags=flags), self.assertRaisesRegex(ValueError, "select PROFILE"):
                validate_flags(flags)

    def test_invalid_quoting_and_missing_definition_fail(self):
        for flags in ('-D "unfinished', '-D', '-D=0'):
            with self.subTest(flags=flags), self.assertRaises(ValueError):
                validate_flags(flags)

    def test_single_dash_flag_cli_uses_assignment(self):
        result = subprocess.run([sys.executable, "-B", str(ROOT / "scripts/check_profile_as_args.py"), "--flags=-q"], capture_output=True, text=True, check=False)
        self.assertEqual(0, result.returncode, result.stderr)


class MakeFlags(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.make = shutil.which("make")
        if cls.make is None:
            raise AssertionError("GNU Make is required for this bounded gate")

    def setUp(self):
        parent = OUTPUTS
        parent.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="flags-", dir=parent)
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name).resolve()
        self.makefile = (ROOT / "Makefile").read_text(encoding="utf-8")
        atomic_write_bytes(self.project / "Makefile", self.makefile.encode())
        atomic_write_bytes(self.project / "scripts/check_profile_as_args.py", (ROOT / "scripts/check_profile_as_args.py").read_bytes())
        self.events = self.project / "events.json"
        atomic_write_json(self.events, [])
        self.env = dict(os.environ, PROFILE_FLAGS_EVENTS=str(self.events), PYTHONDONTWRITEBYTECODE="1")

    def run_make(self, target, profile="jp", flags=None, dry=True, extra=()):
        command = [self.make, "--no-print-directory", "-j1"]
        if dry:
            command.append("-n")
        command += [target, "PROFILE=" + profile]
        if flags is not None:
            command.append("AS_ARGS=" + flags)
        python = '"%s" -B "%s"' % (Path(sys.executable).as_posix(), FIXTURE.as_posix())
        command += ["PYTHON=" + python, "AS_BIN=" + python + " --assembler", *extra]
        result = subprocess.run(command, cwd=self.project, env=self.env, capture_output=True, text=True, check=False, timeout=30)
        return result

    def expected(self, profile, flags=None):
        return shlex.split("-maxerrors 2" if flags is None else flags) + (["-D", "BuildProfileEU=1"] if profile == "eu" else [])

    def arguments(self, row):
        args = row["arguments"]
        value = next((item.partition("=")[2] for item in args if item.startswith("--as-args=")), None)
        if value is not None:
            return shlex.split(value)
        self.assertEqual("assembler", row["kind"])
        source = args.index("src/main.s")
        start = args.index("-o") + 2
        return args[start:source]

    def test_four_preservation_consumers_dry_run_default_and_custom_flags(self):
        for profile in ("jp", "eu"):
            for flags in (None, "-q -maxerrors 2", "-q"):
                for target in ("init", "build", "verify", "build/main.lst" if profile == "jp" else "build/eu/main.lst"):
                    with self.subTest(profile=profile, flags=flags, target=target):
                        result = self.run_make(target, profile, flags)
                        self.assertEqual(0, result.returncode, result.stderr)
                        output = result.stdout
                        expected = shlex.join(self.expected(profile, flags))
                        self.assertIn('--flags="%s"' % ("-maxerrors 2" if flags is None else flags), output)
                        if target.endswith(".lst"):
                            self.assertIn(" " + expected + " src/main.s", output)
                        else:
                            self.assertIn('--as-args="%s"' % expected, output)
                        self.assertFalse(list(self.project.rglob("*.bin")))

    def test_verify_all_recursive_dry_run_keeps_both_profile_arguments(self):
        result = self.run_make("verify-all", flags="-q")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn('--as-args="-q"', result.stdout)
        self.assertIn('--as-args="-q -D BuildProfileEU=1"', result.stdout)

    def test_caller_cannot_override_mandatory_internal_variables(self):
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                result = self.run_make("build", profile, "-q", extra=("PROFILE_AS_ARGS=-D BuildProfileEU=0", "PRESERVATION_AS_ARGS=-D BuildProfileEU=0"))
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertIn('--as-args="%s"' % shlex.join(self.expected(profile, "-q")), result.stdout)
                self.assertNotIn("BuildProfileEU=0", result.stdout)

    def test_stub_runs_init_build_verify_and_listing_without_real_outputs(self):
        for profile in ("jp", "eu"):
            for target in ("init", "build", "verify", "build/main.lst" if profile == "jp" else "build/eu/main.lst"):
                with self.subTest(profile=profile, target=target):
                    atomic_write_json(self.events, [])
                    result = self.run_make(target, profile, "-q", dry=False)
                    self.assertEqual(0, result.returncode, result.stderr)
                    rows = json.loads(self.events.read_text(encoding="utf-8"))
                    consumer = next(row for row in rows if row["kind"] == "assembler" or row["arguments"][0].endswith(("init_project.py", "build_rom.py")))
                    self.assertEqual(self.expected(profile, "-q"), self.arguments(consumer))
                    checker = next(index for index, row in enumerate(rows) if row["arguments"][0].endswith("check_profile_as_args.py"))
                    self.assertLess(checker, rows.index(consumer))
                    self.assertFalse(list(self.project.rglob("*.bin")))
                    self.assertFalse(list(self.project.rglob("*.p")))
                    self.assertFalse(list(self.project.rglob("*.lst")))

    def test_conflicting_profile_flags_fail_before_any_preservation_consumer(self):
        for profile in ("jp", "eu"):
            for target in ("init", "build", "verify", "build/main.lst" if profile == "jp" else "build/eu/main.lst"):
                with self.subTest(profile=profile, target=target):
                    atomic_write_json(self.events, [])
                    result = self.run_make(target, profile, "-DbUiLdPrOfIlEeU=0", dry=False)
                    self.assertNotEqual(0, result.returncode)
                    self.assertIn("select PROFILE", result.stderr)
                    rows = json.loads(self.events.read_text(encoding="utf-8"))
                    self.assertEqual(1, len(rows))
                    self.assertTrue(rows[0]["arguments"][0].endswith("check_profile_as_args.py"))

    def test_existing_listing_order_only_check_does_not_force_reassembly(self):
        target = "build/eu/main.lst"
        atomic_write_bytes(self.project / target, b"private marker, not an AS listing")
        result = self.run_make(target, "eu", "-q", dry=False)
        self.assertEqual(0, result.returncode, result.stderr)
        rows = json.loads(self.events.read_text(encoding="utf-8"))
        self.assertEqual(1, len(rows))
        self.assertTrue(rows[0]["arguments"][0].endswith("check_profile_as_args.py"))

    def test_content_keeps_its_own_manifest_profile_define(self):
        manifest = {"assembler_defines": {"jp": [], "eu": ["BuildProfileEU=1"]}}
        for preservation in ("jp", "eu"):
            for content in ("jp", "eu"):
                for flags in (None, "-q -maxerrors 2", "-q"):
                    with self.subTest(preservation=preservation, content=content, flags=flags):
                        base = "-maxerrors 2" if flags is None else flags
                        result = self.run_make("build-content", preservation, flags, extra=("CONTENT_PROFILE=" + content,))
                        self.assertEqual(0, result.returncode, result.stderr)
                        self.assertIn('--as-args="%s"' % base, result.stdout)
                        self.assertEqual(self.expected(content, base), shlex.split(assembler_args(base, manifest, content)))

    def test_split_has_no_assembler_consumer_and_keeps_regional_reference(self):
        for profile, letter in (("jp", "J"), ("eu", "E")):
            result = self.run_make("split", profile, "-q")
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn('Alien Soldier (%s) [!].bin' % letter, result.stdout)
            self.assertNotIn("--assembler", result.stdout)

    def test_content_profile_conflict_is_rejected_before_init_or_builder(self):
        for profile in ("jp", "eu"):
            for content in ("jp", "eu"):
                with self.subTest(profile=profile, content=content):
                    atomic_write_json(self.events, [])
                    result = self.run_make("build-content", profile, "-DBuildProfileEU=0", dry=False,
                                           extra=("CONTENT_PROFILE=" + content,))
                    self.assertNotEqual(0, result.returncode)
                    self.assertIn("select PROFILE", result.stderr)
                    rows = json.loads(self.events.read_text(encoding="utf-8"))
                    self.assertEqual(1, len(rows))
                    self.assertTrue(rows[0]["arguments"][0].endswith("check_profile_as_args.py"))


if __name__ == "__main__":
    unittest.main()
