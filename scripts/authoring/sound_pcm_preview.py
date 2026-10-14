#!/usr/bin/env python3
"""Export one source-backed DPCM sample as an explicitly timed PCM WAV."""

from __future__ import annotations

import argparse
import io
import sys
import wave
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.content_workspace import (  # noqa: E402
    ContentError, artifact_path, checked_path, load_manifest,
)
from authoring.sound_pcm_codec import decode_dpcm, load_tables  # noqa: E402
from authoring.sound_pcm_model import load_document, validate_document  # noqa: E402


MANIFEST = "config/authoring/content_studios.json"
ARTIFACT = "sound_pcm_samples"
MIN_AUDITION_RATE = 1000
MAX_AUDITION_RATE = 48000


def sample_from_document(document: dict, bank_name: str, sample_index: int) -> dict:
    for bank in document["banks"]:
        if bank["name"] != bank_name:
            continue
        for sample in bank["samples"]:
            if sample["index"] == sample_index:
                return sample
        raise ValueError("%s has no sample %d" % (bank_name, sample_index))
    raise ValueError("unknown PCM bank: %s" % bank_name)


def wav_bytes(sample: dict, rate: int, high: bytes, low: bytes) -> bytes:
    if isinstance(rate, bool) or not isinstance(rate, int) or not (
        MIN_AUDITION_RATE <= rate <= MAX_AUDITION_RATE
    ):
        raise ValueError(
            "audition rate must be an integer between %d and %d Hz"
            % (MIN_AUDITION_RATE, MAX_AUDITION_RATE)
        )
    encoded = bytes.fromhex(sample["data"])
    if len(encoded) != sample["byte_count"]:
        raise ValueError("PCM sample encoded length differs from its header")
    decoded = decode_dpcm(encoded, high, low)
    stream = io.BytesIO()
    with wave.open(stream, "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(1)
        output.setframerate(rate)
        output.writeframes(decoded)
    return stream.getvalue()


def load_workspace_sample(
    project: Path, profile: str, bank_name: str, sample_index: int,
) -> dict:
    manifest = load_manifest(checked_path(project, MANIFEST), project)
    artifact = next(item for item in manifest["artifacts"] if item["id"] == ARTIFACT)
    document = load_document(artifact_path(project, manifest, profile, artifact))
    validate_document(document, project, profile)
    return sample_from_document(document, bank_name, sample_index)


def export_path(root: Path, directory: Path, destination: Path) -> Path:
    """Keep WAV exports out of the source, the workspace and the build owners."""
    destination = Path(destination).absolute()
    if destination.suffix.lower() != ".wav" or ".." in destination.parts:
        raise ValueError("PCM export requires a WAV without path aliases")
    for path in (destination, *destination.parents):
        if path.is_symlink() or getattr(path, "is_junction", lambda: False)():
            raise ValueError("PCM WAV export crosses a link")
    destination = destination.resolve()
    if destination.is_relative_to(directory.resolve()):
        raise ValueError("PCM export cannot replace a workspace file")
    root = root.resolve()
    if destination.is_relative_to(root) and not destination.is_relative_to(root/"build/audio-exports"):
        raise ValueError("in-project WAV exports must use build/audio-exports")
    return destination


def export_wav(
    project: Path, profile: str, bank_name: str, sample_index: int,
    rate: int, destination: Path,
) -> int:
    destination = export_path(project, project / "content/workspace", destination)
    sample = load_workspace_sample(project, profile, bank_name, sample_index)
    high, low = load_tables(project)
    payload = wav_bytes(sample, rate, high, low)
    destination.parent.mkdir(parents=True, exist_ok=True)
    from authoring.atomic_output import atomic_write_bytes as _write_bytes
    _write_bytes(destination, payload)
    return sample["byte_count"] * 2


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    parser.add_argument("--bank", required=True)
    parser.add_argument("--sample", required=True, type=int)
    parser.add_argument("--rate", required=True, type=int)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    try:
        count = export_wav(
            Path(args.root).resolve(), args.profile, args.bank,
            args.sample, args.rate, Path(args.output),
        )
        print("[OK] %s sample %d: %d PCM values at user-selected %d Hz -> %s" % (
            args.bank, args.sample, count, args.rate, args.output))
        return 0
    except (OSError, ValueError, ContentError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
