"""Select a clean pinned native runtime and record its observed build identity."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import runtime_isolation
from verify_toolchain import check_emulator_commit, emulator_git


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def environment_identity(root: Path, executable: Path) -> dict:
    executable = executable.resolve()
    checkout = executable.parent.parent
    manifest = json.loads((root / "config/toolchain.json").read_text(encoding="utf-8"))
    component = next(item for item in manifest["components"] if item["id"] == "emulator")
    declared = Path(component["files"]["any"][0]["path"])
    if executable != checkout / declared.parent.name / declared.name:
        raise ValueError("selected emulator is not the declared runtime executable")
    errors, notes = [], []
    check_emulator_commit(component, errors, notes, checkout)
    tree = emulator_git(checkout, ["rev-parse", "HEAD^{tree}"], errors)
    if errors:
        raise ValueError("; ".join(errors))
    return {"source_commit": component["source_commit"], "source_tree": tree,
            "executable_path": str(executable), "executable_sha256": digest(executable),
            "config_loader": runtime_isolation.native_config_contract(checkout),
            "isolation_sha256": digest(Path(runtime_isolation.__file__)),
            "environment_verifier_sha256": digest(Path(__file__))}
