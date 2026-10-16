"""Seed an owned Gens startup config before enabling ordinary native sound.

This repairs launch ordering, not a chip core or an audio-fidelity contract.
"""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re
import sys

SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.atomic_output import atomic_write_bytes
from authoring.content_workspace import checked_path
from runtime_environment import environment_identity
from runtime_isolation import validate_isolation, validate_private_config

NATIVE_FILES = ("src/G_main.cpp", "src/ParseCmdLine.cpp", "src/save.cpp",
                "src/G_dsound.cpp", "src/Gens.cpp")
SNAPSHOT = "sound-startup-seed.ini"
STATE_SITE = b"[Sound]\nState=1\n"
SCOPE = "private-startup-state-zero-before-explicit-sound-enable"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def native_contract(checkout: Path) -> dict:
    """Check the actual launch chain; callers separately authenticate the pin."""
    source = {name: (checkout / name).read_text(encoding="utf-8", errors="replace")
              for name in NATIVE_FILES}
    compact = {name: re.sub(r"\s+", "", text) for name, text in source.items()}
    requirements = {
        "src/G_main.cpp": (
            "Sound_Enable=0;", "Sound_Initialised=0;",
            'strcpy(Str_Tmp,Gens_Path);strcat(Str_Tmp,"\\\\gens.cfg");Load_Config(Str_Tmp,NULL);',
            "if(!Init_Sound(hWnd)){Sound_Enable=0;YM2612_Enable=0;PSG_Enable=0;DAC_Enable=0;",
            "Sound_Enable=1;Play_Sound();"),
        "src/ParseCmdLine.cpp": (
            'elsenewCommand="";switch(x){',
            'case15://-nosoundSound_Enable=0;break;'),
        "src/save.cpp": (
            'new_val=GetPrivateProfileInt("Sound","State",1,Conf_File);',
            "if(new_val!=Sound_Enable){if(Change_Sound(HWnd)){"),
        "src/G_dsound.cpp": ("if(Sound_Initialised)return0;End_Sound();",),
        "src/Gens.cpp": (
            "if(Sound_Enable){End_Sound();if(!Init_Sound(HWnd))Sound_Enable=0;elsePlay_Sound();}",),
    }
    # Comments may separate the parser fallback from the switch, but cannot
    # stand in for code. Remove them before checking that unconditional path.
    code = re.sub(r"/\*.*?\*/|//[^\n]*", "", source["src/ParseCmdLine.cpp"], flags=re.S)
    parser = re.sub(r"\s+", "", code)
    requirements["src/ParseCmdLine.cpp"] = (
        'elsenewCommand="";switch(x){', "case15:Sound_Enable=0;break;")
    compact["src/ParseCmdLine.cpp"] = parser
    for name, fragments in requirements.items():
        if any(fragment not in compact[name] for fragment in fragments):
            raise ValueError("native sound-startup source chain changed: " + name)
    main = source["src/G_main.cpp"].split("int PASCAL WinMain", 1)[1]
    cli = source["src/ParseCmdLine.cpp"]
    if (main.index("Init(hInst, nCmdShow);") > main.index("ParseCmdLine(lpCmdLine, HWnd)")
            or cli.index("case 15: //-nosound") > cli.index("Load_Config((char*)CfgToLoad.c_str(), NULL);")
            or cli.index("Load_Config((char*)CfgToLoad.c_str(), NULL);") > cli.index("GensLoadRom(RomToLoad.c_str());")):
        raise ValueError("native sound-startup config/CLI/ROM order changed")
    return {"scope": SCOPE, "source_sha256": {
        name: digest((checkout / name).read_bytes()) for name in NATIVE_FILES}}


def seed_bytes(config: bytes) -> bytes:
    if config.count(STATE_SITE) != 1:
        raise ValueError("sound startup requires exactly one generated State1 site")
    return config.replace(STATE_SITE, b"[Sound]\nState=0\n", 1)


def owned_config(session: Path, path: Path) -> Path:
    if path.is_absolute():
        try:
            relative = path.relative_to(session)
        except ValueError as error:
            raise ValueError("sound startup config escapes its session") from error
    else:
        relative = path
    return checked_path(session, relative)


def prepare(isolation: dict, config_path: Path, *, startup: str = "runtime") -> dict:
    """Create one immutable seed and a disposable native startup working copy."""
    validate_isolation(isolation, startup=startup)  # Must still be empty.
    session = Path(isolation["session_directory"])
    config_path = owned_config(session, config_path)
    validate_private_config(isolation, config_path)
    seed = seed_bytes(config_path.read_bytes())
    snapshot = checked_path(session, SNAPSHOT)
    working = checked_path(Path(isolation["startup_directories"][startup]), "gens.cfg")
    if snapshot.exists() or working.exists():
        raise ValueError("sound startup never overwrites an earlier seed/input")
    atomic_write_bytes(snapshot, seed)
    atomic_write_bytes(working, seed)
    record = {"schema_version": 1, "scope": SCOPE, "startup": startup,
              "snapshot": SNAPSHOT, "working": "gens.cfg", "sha256": digest(seed),
              "explicit_config_sha256": isolation["config_sha256"]}
    validate(record, isolation, config_path, launched=False)
    return record


def validate(record: dict, isolation: dict, config_path: Path, *, launched: bool) -> None:
    if (type(record) is not dict or set(record) != {
            "schema_version", "scope", "startup", "snapshot", "working", "sha256", "explicit_config_sha256"}
            or type(record["schema_version"]) is not int or record["schema_version"] != 1
            or record["scope"] != SCOPE or record["snapshot"] != SNAPSHOT or record["working"] != "gens.cfg"
            or record["explicit_config_sha256"] != isolation["config_sha256"]
            or type(record["startup"]) is not str
            or record["startup"] not in isolation["startup_directories"] or type(launched) is not bool):
        raise ValueError("sound startup seed contract differs")
    validate_isolation(isolation, startup=record["startup"], finished=True)
    session = Path(isolation["session_directory"])
    config_path = owned_config(session, config_path)
    validate_private_config(isolation, config_path)
    expected = seed_bytes(config_path.read_bytes())
    snapshot = checked_path(session, SNAPSHOT)
    if snapshot.read_bytes() != expected or digest(expected) != record["sha256"]:
        raise ValueError("immutable sound startup seed changed")
    startup = Path(isolation["startup_directories"][record["startup"]])
    if not launched:
        if ({path.name for path in startup.iterdir()} != {"gens.cfg"}
                or checked_path(startup, "gens.cfg").read_bytes() != expected):
            raise ValueError("sound startup prelaunch working copy changed")
    # The owned native working copy may be rewritten by normal shutdown.
    # It is an allowed output, never an immutable input substituted for seed.


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gens", type=Path, required=True)
    args = parser.parse_args()
    root = SCRIPT_ROOT.parent
    environment_identity(root, args.gens)
    native_contract(args.gens.resolve().parent.parent)
    print("[OK] selected clean-pin sound startup source chain; no audio fidelity claim")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
