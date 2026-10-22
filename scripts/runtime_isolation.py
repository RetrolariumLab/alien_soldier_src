"""Source-proved private Gens paths for owned runtime sessions."""

from __future__ import annotations

import configparser
import hashlib
import os
import re
from pathlib import Path


PATH_KEYS = {
    "Rom path": "Rom_Dir",
    "Save path": "State_Dir",
    "SRAM path": "SRAM_Dir",
    "BRAM path": "BRAM_Dir",
    "Dump path": "Dump_Dir",
    "Dump GYM path": "Dump_GYM_Dir",
    "Screen Shot path": "ScrShot_Dir",
    "Patch path": "Patch_Dir",
    "IPS Patch path": "IPS_Dir",
    "Movie path": "Movie_Dir",
    "Watch path": "Watch_Dir",
    "Lua path": "Lua_Dir",
}
BIOS_KEYS = (
    "Genesis Bios",
    "USA CD Bios",
    "EUROPE CD Bios",
    "JAPAN CD Bios",
    "32X 68000 Bios",
    "32X Master SH2 Bios",
    "32X Slave SH2 Bios",
)
NATIVE_FILES = (
    "src/save.cpp",
    "src/rom.cpp",
    "src/ggenie.cpp",
    "src/Gens.cpp",
    "src/G_main.cpp",
    "src/ParseCmdLine.cpp",
)
SCHEMA_VERSION = 1


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def native_config_contract(checkout: Path) -> dict:
    """Verify real path keys, direct concatenation and startup cwd ownership."""
    checkout = checkout.resolve()
    sources = {name: (checkout / name).read_text(encoding="utf-8", errors="replace") for name in NATIVE_FILES}
    pattern = re.compile(
        r'GetPrivateProfileString\("General",\s*"([^"]+)",\s*("(?:[^"\\]|\\.)*"|\w+),\s*&?(\w+)\[0\],\s*1024,\s*Conf_File\)'
    )
    entries = {key: (default, variable) for key, default, variable in pattern.findall(sources["src/save.cpp"])}
    actual_paths = {key for key in entries if key.endswith(" path")}
    if actual_paths != set(PATH_KEYS):
        raise ValueError("native General path-key inventory changed")
    for key, variable in PATH_KEYS.items():
        default = r'".\\"' if key == "Rom path" else "Rom_Dir"
        if entries.get(key) != (default, variable):
            raise ValueError("native General path reader changed: %s" % key)
    if any(key not in entries or entries[key][0] != "Rom_Dir" for key in BIOS_KEYS):
        raise ValueError("native BIOS path defaults changed")
    requirements = {
        "src/rom.cpp": (
            "void Fill_Infos(void)",
            "IPS_Patching();",
            'strcpy(Name, IPS_Dir);strcat(Name, Rom_Name);strcat(Name, ".ips");',
        ),
        "src/ggenie.cpp": (
            'strcpy(Name, Patch_Dir);strcat(Name, Rom_Name);strcat(Name, ".pat");',
            "CheatWrite<unsigned char>(addr,(Liste_GG[i].data >> (j<<3))&0xFF);",
        ),
        "src/Gens.cpp": ("Load_SRAM();", "Load_Patch_File();", "Patch_Codes();"),
        "src/save.cpp": (
            'strcpy(Name, SRAM_Dir);strcat(Name, Rom_Name);strcat(Name, ".srm");',
            'Country = GetPrivateProfileInt("CPU", "Country", -1, Conf_File);',
            'Auto_Fix_CS = GetPrivateProfileInt("Options", "Auto Fix Checksum", 0, Conf_File);',
        ),
        "src/G_main.cpp": (
            "GetCurrentDirectory(1024, Gens_Path);",
            'strcat(Gens_Path, "\\\\");',
            "GetCurrentDirectory(1024, Language_Path);",
            'strcat(Language_Path, "\\\\language.dat");',
            "LFile = CreateFile(Language_Path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);",
            'WritePrivateProfileString("English", "Menu Language", "&English menu", Language_Path);',
            'strcpy(Str_Tmp, Gens_Path);strcat(Str_Tmp, "\\\\gens.cfg");Load_Config(Str_Tmp, NULL);',
            'strcpy(Str_Tmp, Gens_Path);strcat(Str_Tmp, "Gens.cfg");Save_Config(Str_Tmp);',
            "Init(hInst, nCmdShow);",
            "Init_Genesis_Bios();",
        ),
    }
    for name, fragments in requirements.items():
        compact = re.sub(r"\s+", "", sources[name])
        if any(re.sub(r"\s+", "", fragment) not in compact for fragment in fragments):
            raise ValueError("native isolation source proof changed: %s" % name)
    cli = sources["src/ParseCmdLine.cpp"]
    if cli.index("Load_Config((char*)CfgToLoad.c_str(), NULL);") > cli.index("GensLoadRom(RomToLoad.c_str());"):
        raise ValueError("native config is not loaded before selected ROM")
    main = sources["src/G_main.cpp"].split("int PASCAL WinMain", 1)[1]
    if main.index("Init(hInst, nCmdShow);") > main.index("ParseCmdLine(lpCmdLine, HWnd)"):
        raise ValueError("native startup directory is not captured before CLI loading")
    return {
        "schema_version": SCHEMA_VERSION,
        "path_keys": list(PATH_KEYS),
        "bios_defaults": list(BIOS_KEYS),
        "startup_directory_source": "GetCurrentDirectory -> Gens_Path",
        "automatic_sidecars": ["<ROM basename>.ips", "<ROM basename>.pat", "<ROM basename>.srm"],
        "source_sha256": {name: _sha((checkout / name).read_bytes()) for name in NATIVE_FILES},
    }


def _is_link(path: Path) -> bool:
    return path.is_symlink() or getattr(path, "is_junction", lambda: False)()


def _safe_directory(path: Path) -> Path:
    if any(_is_link(parent) for parent in (path.absolute(), *path.absolute().parents)):
        raise ValueError("native private path crosses a filesystem link")
    path = path.resolve()
    value = str(path)
    try:
        value.encode("ascii")
    except UnicodeEncodeError as error:
        raise ValueError("native private paths must be ASCII for this ANSI runtime") from error
    if len(value) > 220 or any(char in value for char in "\r\n\0=[]"):
        raise ValueError("native private path exceeds its safe INI/path bound")
    return path


def isolated_config(
    directory: Path,
    *,
    sound: bool = False,
    extra_sections: dict | None = None,
    startup_names: tuple[str, ...] = ("runtime",),
) -> tuple[bytes, dict]:
    """Create fresh empty loader/startup dirs; never place config in Gens Output."""
    directory = _safe_directory(directory)
    if not directory.is_dir():
        raise ValueError("runtime session directory must already exist")
    if (
        not startup_names
        or len(set(startup_names)) != len(startup_names)
        or any(not re.fullmatch(r"[a-z][a-z0-9_-]*", name) for name in startup_names)
    ):
        raise ValueError("private startup names must be unique simple names")
    sidecars = _safe_directory(directory / "native-sidecars")
    sidecars.mkdir()
    startups = {}
    for name in startup_names:
        path = _safe_directory(directory / ("native-startup-" + name))
        path.mkdir()
        startups[name] = str(path)
    paths = {key: str(sidecars) + os.sep for key in PATH_KEYS}
    sections = {
        "General": {**paths, "Intro Style": "0"},
        "Sound": {"State": str(int(sound))},
        "Options": {"Auto Fix Checksum": "0"},
        "CPU": {"Country": "-1"},
    }
    for name, values in (extra_sections or {}).items():
        if not isinstance(name, str) or not isinstance(values, dict) or name.casefold() == "general":
            raise ValueError("extra native config must not override General isolation")
        for key, value in values.items():
            if not isinstance(key, str) or not isinstance(value, (str, int)):
                raise ValueError("extra native config has an invalid key/value")
            if any(char in str(key) + str(value) + name for char in "\r\n\0[]") or "=" in key:
                raise ValueError("extra native config contains an INI injection")
        if name not in sections and name.casefold() in {key.casefold() for key in sections}:
            raise ValueError("extra native config contains a duplicate section alias")
        existing = sections.get(name, {})
        if any(key not in existing and key.casefold() in {item.casefold() for item in existing} for key in values):
            raise ValueError("extra native config contains a duplicate key alias")
        if (
            name == "Options"
            and str(values.get("Auto Fix Checksum", "0")) != "0"
            or name == "CPU"
            and str(values.get("Country", "-1")) != "-1"
        ):
            raise ValueError("extra native config changes checksum or automatic regional selection")
        sections.setdefault(name, {}).update({key: str(value) for key, value in values.items()})
    contents = "".join(
        "[%s]\n%s" % (name, "".join("%s=%s\n" % pair for pair in values.items())) for name, values in sections.items()
    ).encode("ascii")
    record = {
        "schema_version": SCHEMA_VERSION,
        "session_directory": str(directory),
        "sidecar_directory": str(sidecars),
        "general_paths": paths,
        "startup_directories": startups,
        "config_sha256": _sha(contents),
    }
    validate_isolation(record)
    return contents, record


def validate_isolation(record: dict, *, startup: str | None = None, finished: bool = False) -> None:
    """Sidecars must stay empty; native startup outputs remain session-private."""
    if record.get("schema_version") != SCHEMA_VERSION:
        raise ValueError("native isolation record version differs")
    session = _safe_directory(Path(record["session_directory"]))
    sidecars = Path(record["sidecar_directory"])
    if (
        _is_link(sidecars)
        or sidecars.resolve() != session / "native-sidecars"
        or not sidecars.is_dir()
        or list(sidecars.iterdir())
    ):
        raise ValueError("native sidecar directory is missing, redirected, or not empty")
    if record.get("general_paths") != {key: str(sidecars.resolve()) + os.sep for key in PATH_KEYS}:
        raise ValueError("native private General path inventory differs")
    directories = record.get("startup_directories")
    if not isinstance(directories, dict) or not directories:
        raise ValueError("native startup directory inventory is missing")
    if startup is not None and startup not in directories:
        raise ValueError("native startup directory is unavailable: %s" % startup)
    for name, value in directories.items():
        path = Path(value)
        if (
            not re.fullmatch(r"[a-z][a-z0-9_-]*", name)
            or _is_link(path)
            or path.resolve() != session / ("native-startup-" + name)
            or not path.is_dir()
        ):
            raise ValueError("native startup directory is missing or redirected")
        if startup is not None and name != startup:
            continue
        allowed = {"gens.cfg", "language.dat"} if finished else set()
        if any(
            not entry.is_file() or _is_link(entry) or entry.name.casefold() not in allowed for entry in path.iterdir()
        ):
            raise ValueError("native startup directory contains an unexpected input/output")


def validate_private_config(record: dict, path: Path) -> None:
    data = path.read_bytes()
    if _sha(data) != record["config_sha256"]:
        raise ValueError("private native config changed")
    parser = configparser.ConfigParser(interpolation=None)
    parser.read_string(data.decode("ascii"))
    general = parser["General"]
    if any(general.get(key) != value for key, value in record["general_paths"].items()):
        raise ValueError("private native config does not bind every source-owned General path")
    if parser["Options"].get("Auto Fix Checksum") != "0" or parser["CPU"].get("Country") != "-1":
        raise ValueError("private native config changes checksum or automatic regional selection")
