from __future__ import annotations

import io
import sys
import tempfile
import unittest
from unittest import mock
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_pcm_codec import decode_dpcm, load_tables  # noqa: E402
from authoring import atomic_output, sound_pcm_codec, sound_pcm_preview as preview  # noqa: E402
from authoring.sound_pcm_preview import (  # noqa: E402
    load_workspace_sample,
    sample_from_document,
    wav_bytes,
)


class SoundPCMPreviewTests(unittest.TestCase):
    def test_wav_contains_exact_driver_decoded_levels(self) -> None:
        sample = load_workspace_sample(ROOT, "jp", "Sound_PCMBank1", 0)
        high, low = load_tables(ROOT)
        output = wav_bytes(sample, 11025, high, low)
        with wave.open(io.BytesIO(output), "rb") as reader:
            self.assertEqual(1, reader.getnchannels())
            self.assertEqual(1, reader.getsampwidth())
            self.assertEqual(11025, reader.getframerate())
            self.assertEqual(sample["byte_count"] * 2, reader.getnframes())
            self.assertEqual(
                decode_dpcm(bytes.fromhex(sample["data"]), high, low),
                reader.readframes(reader.getnframes()),
            )

    def test_rate_is_explicit_and_bounded(self) -> None:
        sample = {"data": "00", "byte_count": 1}
        high, low = load_tables(ROOT)
        for rate in (False, 0, 999, 48001, 11025.0):
            with self.subTest(rate=rate):
                with self.assertRaisesRegex(ValueError, "audition rate"):
                    wav_bytes(sample, rate, high, low)

    def test_lookup_rejects_unknown_bank_and_sample(self) -> None:
        document = {
            "banks": [
                {
                    "name": "Sound_PCMBank1",
                    "samples": [{"index": 0, "data": "00"}],
                }
            ]
        }
        self.assertEqual("00", sample_from_document(document, "Sound_PCMBank1", 0)["data"])
        with self.assertRaisesRegex(ValueError, "unknown PCM bank"):
            sample_from_document(document, "Sound_PCMBank2", 0)
        with self.assertRaisesRegex(ValueError, "has no sample"):
            sample_from_document(document, "Sound_PCMBank1", 1)

    def test_protected_export_fails_before_workspace_load_decode_or_write(self) -> None:
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary) / "project"
                root.mkdir()
                for relative in (
                    "src/keep.wav",
                    "data/keep.wav",
                    "reference/keep.wav",
                    "content/workspace/%s/sound/keep.wav" % profile,
                    "build/content/%s/native-pcm/session-old/native.wav" % profile,
                    "build/runtime-emulator/canonical-pcm-probe-old/keep.wav",
                    "config/keep.wav",
                    "Alien Soldier.bin",
                ):
                    destination = root / relative
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    destination.write_bytes(b"protected fixture input")
                    before = {
                        path.relative_to(root).as_posix(): path.read_bytes()
                        for path in root.rglob("*")
                        if path.is_file()
                    }
                    with (
                        mock.patch.object(preview, "load_workspace_sample") as load,
                        mock.patch.object(preview, "load_tables") as tables,
                        mock.patch.object(preview, "wav_bytes") as decode,
                        mock.patch.object(atomic_output, "atomic_write_bytes") as write,
                    ):
                        with self.subTest(relative=relative), self.assertRaises(ValueError):
                            preview.export_wav(root, profile, "fixture", 0, 11025, destination)
                        load.assert_not_called()
                        tables.assert_not_called()
                        decode.assert_not_called()
                        write.assert_not_called()
                    after = {
                        path.relative_to(root).as_posix(): path.read_bytes()
                        for path in root.rglob("*")
                        if path.is_file()
                    }
                    self.assertEqual(before, after)

    def test_cli_does_not_resolve_away_output_parent_alias_before_policy(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "project"
            root.mkdir()
            target = root / "build/audio-exports/../audio-exports/out.wav"
            argv = [
                "sound_pcm_preview.py",
                "--root",
                str(root),
                "--profile",
                "jp",
                "--bank",
                "fixture",
                "--sample",
                "0",
                "--rate",
                "11025",
                "--output",
                str(target),
            ]
            with (
                mock.patch.object(sys, "argv", argv),
                mock.patch.object(sys, "stderr", io.StringIO()) as error,
                mock.patch.object(preview, "load_workspace_sample") as load,
                mock.patch.object(preview, "load_tables") as tables,
                mock.patch.object(preview, "wav_bytes") as decode,
                mock.patch.object(atomic_output, "atomic_write_bytes") as write,
            ):
                self.assertEqual(preview.main(), 1)
                self.assertIn("path aliases", error.getvalue())
                load.assert_not_called()
                tables.assert_not_called()
                decode.assert_not_called()
                write.assert_not_called()
            self.assertEqual(list(root.rglob("*")), [])

    def test_cli_rejects_real_output_symlink_without_mutating_its_target(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            parent = Path(temporary)
            root = parent / "project"
            root.mkdir()
            external = parent / "preserve.wav"
            external.write_bytes(b"do not follow this link")
            link = root / "build/audio-exports/link.wav"
            link.parent.mkdir(parents=True)
            try:
                link.symlink_to(external)
            except OSError:
                # Some hosts cannot create symlinks. The portable fallback
                # still tests rejection before load/write, not a success skip.
                def linked(path):
                    return path == link

                with (
                    mock.patch.object(Path, "is_symlink", autospec=True, side_effect=linked),
                    mock.patch.object(preview, "load_workspace_sample") as load,
                ):
                    with self.assertRaisesRegex(ValueError, "link"):
                        preview.export_wav(root, "jp", "fixture", 0, 11025, link)
                    load.assert_not_called()
            else:
                argv = [
                    "sound_pcm_preview.py",
                    "--root",
                    str(root),
                    "--profile",
                    "jp",
                    "--bank",
                    "fixture",
                    "--sample",
                    "0",
                    "--rate",
                    "11025",
                    "--output",
                    str(link),
                ]
                with (
                    mock.patch.object(sys, "argv", argv),
                    mock.patch.object(sys, "stderr", io.StringIO()) as error,
                    mock.patch.object(preview, "load_workspace_sample") as load,
                    mock.patch.object(preview, "wav_bytes") as decode,
                    mock.patch.object(atomic_output, "atomic_write_bytes") as write,
                ):
                    self.assertEqual(preview.main(), 1)
                    self.assertIn("link", error.getvalue())
                    load.assert_not_called()
                    decode.assert_not_called()
                    write.assert_not_called()
                self.assertTrue(link.is_symlink())
            self.assertEqual(external.read_bytes(), b"do not follow this link")

    def test_allowed_local_and_explicit_external_exports_keep_exact_user_rate(self) -> None:
        sample = {"data": "127F", "byte_count": 2}
        high, low = sound_pcm_codec.expected_high_table(), sound_pcm_codec.expected_low_table()
        for profile, rate in (("jp", 11025), ("eu", 22050)):
            with self.subTest(profile=profile), tempfile.TemporaryDirectory() as temporary:
                parent = Path(temporary)
                root = parent / "project"
                root.mkdir()
                for destination in (root / "build/audio-exports/decoded.wav", parent / "explicit-user-output.wav"):
                    with (
                        mock.patch.object(preview, "load_workspace_sample", return_value=sample) as load,
                        mock.patch.object(preview, "load_tables", return_value=(high, low)),
                    ):
                        self.assertEqual(preview.export_wav(root, profile, "fixture", 0, rate, destination), 4)
                        load.assert_called_once_with(root, profile, "fixture", 0)
                    self.assertEqual(destination.read_bytes(), preview.wav_bytes(sample, rate, high, low))
                    with wave.open(io.BytesIO(destination.read_bytes()), "rb") as reader:
                        self.assertEqual(
                            (reader.getnchannels(), reader.getsampwidth(), reader.getframerate(), reader.getnframes()),
                            (1, 1, rate, 4),
                        )
                        self.assertEqual(reader.readframes(4), decode_dpcm(bytes.fromhex(sample["data"]), high, low))


if __name__ == "__main__":
    unittest.main()
