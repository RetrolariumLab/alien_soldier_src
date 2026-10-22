"""Write editor documents through an exclusive sibling temporary file."""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path
from typing import Any


def atomic_write_bytes(path: Path, payload: bytes) -> None:
    """Replace one output without following a predictable temporary link."""
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", prefix="." + path.name + ".", suffix=".tmp", dir=path.parent, delete=False
        ) as stream:
            temporary = Path(stream.name)
            stream.write(payload)
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def atomic_write_text(path: Path, text: str) -> None:
    """Write source text as UTF-8 without platform newline translation."""
    atomic_write_bytes(path, text.encode("utf-8"))


def atomic_write_json(path: Path, document: dict[str, Any], *, ensure_ascii: bool = False) -> None:
    """Keep the existing two-space JSON format and a single final LF."""
    payload = (json.dumps(document, indent=2, ensure_ascii=ensure_ascii) + "\n").encode("utf-8")
    atomic_write_bytes(path, payload)
