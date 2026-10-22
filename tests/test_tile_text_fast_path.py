from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import compressed_graphics_model as compressed  # noqa: E402
from authoring import graphics_studio_model as graphics  # noqa: E402


TILE_BYTES = 32
READERS = (graphics.tile_text, compressed.tile_text)


def legacy_tile_text(data, offset):
    """The former decode_tile plus uppercase-nibble loop, unchanged."""
    if offset + TILE_BYTES > len(data):
        raise ValueError("tile at %d runs past %d bytes" % (offset, len(data)))
    pixels = []
    for byte in data[offset : offset + TILE_BYTES]:
        pixels.append(byte >> 4)
        pixels.append(byte & 0x0F)
    return "".join("%X" % pixel for pixel in pixels)


def outcome(reader, data, offset):
    try:
        value = reader(data, offset)
    except Exception as error:
        return ("raise", type(error), error.args)
    return ("return", type(value), value)


class TrackedBytes(bytes):
    def __new__(cls, payload):
        instance = super().__new__(cls, payload)
        instance.events = []
        return instance

    def __len__(self):
        self.events.append(("len",))
        return super().__len__()

    def __getitem__(self, key):
        self.events.append(("slice", key.start, key.stop, key.step))
        return super().__getitem__(key)

    def hex(self, *args, **kwargs):
        raise AssertionError("bytes subclass must not enter the hex fast path")


class TrackedBytearray(bytearray):
    def __init__(self, payload):
        super().__init__(payload)
        self.events = []

    def __len__(self):
        self.events.append(("len",))
        return super().__len__()

    def __getitem__(self, key):
        self.events.append(("slice", key.start, key.stop, key.step))
        return super().__getitem__(key)

    def hex(self, *args, **kwargs):
        raise AssertionError("bytearray subclass must not enter the hex fast path")


class IntOffset(int):
    """An int subclass remains on the existing sequence/arithmetic path."""


class IndexOffset:
    def __init__(self, value):
        self.value = value

    def __index__(self):
        return self.value

    def __add__(self, other):
        return self.value + other


class EqualByteTypes(type):
    def __eq__(cls, other):
        return other is bytes or other is bytearray


class EqualByteSequence(list, metaclass=EqualByteTypes):
    """An unrelated accepted sequence must not select a builtin fast path."""


class TileTextFastPathTests(unittest.TestCase):
    def test_every_byte_value_matches_legacy_for_exact_byte_types(self):
        for reader in READERS:
            for kind in (bytes, bytearray):
                data = kind(range(256))
                for offset in range(0, len(data), TILE_BYTES):
                    with self.subTest(reader=reader.__module__, kind=kind, offset=offset):
                        actual = reader(data, offset)
                        self.assertIs(type(actual), str)
                        self.assertEqual(legacy_tile_text(data, offset), actual)
                        self.assertEqual(64, len(actual))
                        self.assertEqual(actual.upper(), actual)

    def test_bounds_and_negative_offsets_preserve_legacy_results_and_errors(self):
        for reader in READERS:
            for kind in (bytes, bytearray):
                for size in (0, 1, 31, 32, 33, 64, 256):
                    data = kind(range(size))
                    offsets = (
                        -size - 33,
                        -size - 1,
                        -size,
                        -size + 1,
                        -33,
                        -32,
                        -31,
                        -1,
                        0,
                        1,
                        size - 32,
                        size - 31,
                        size,
                        size + 1,
                    )
                    for offset in offsets:
                        with self.subTest(reader=reader.__module__, kind=kind, size=size, offset=offset):
                            self.assertEqual(outcome(legacy_tile_text, data, offset), outcome(reader, data, offset))

    def test_mutable_bytearray_is_read_fresh_without_retained_text(self):
        for reader in READERS:
            with self.subTest(reader=reader.__module__):
                data = bytearray(range(TILE_BYTES))
                original = reader(data, 0)
                data[0] = 0xEF
                changed = reader(data, 0)
                self.assertNotEqual(original, changed)
                self.assertEqual("EF" + original[2:], changed)
                self.assertEqual(legacy_tile_text(data, 0), changed)
                self.assertEqual(changed, reader(data, 0))

    def test_other_sequences_keep_the_legacy_nibble_loop(self):
        payload = bytes(range(64))
        sequences = (
            list(payload),
            tuple(payload),
            memoryview(payload),
            EqualByteSequence(payload),
            [-16, 256, 511] + [0] * 61,
        )
        for reader in READERS:
            for data in sequences:
                for offset in (-65, -64, -33, -1, 0, 1, 32, 33):
                    with self.subTest(reader=reader.__module__, kind=type(data), offset=offset):
                        self.assertEqual(outcome(legacy_tile_text, data, offset), outcome(reader, data, offset))

    def test_byte_subclasses_keep_legacy_slice_protocol_and_never_use_hex(self):
        for reader in READERS:
            for kind in (TrackedBytes, TrackedBytearray):
                for offset in (-65, -64, -33, -1, 0, 32, 33):
                    with self.subTest(reader=reader.__module__, kind=kind, offset=offset):
                        original = kind(range(64))
                        actual = kind(range(64))
                        self.assertEqual(outcome(legacy_tile_text, original, offset), outcome(reader, actual, offset))
                        self.assertEqual(original.events, actual.events)

    def test_nonexact_offsets_keep_legacy_results_and_errors(self):
        offsets = (False, True, IntOffset(0), IntOffset(-33), IndexOffset(1), IndexOffset(-65), 1.0, "1", None, 1 + 0j)
        for reader in READERS:
            for kind in (bytes, bytearray):
                data = kind(range(64))
                for offset in offsets:
                    with self.subTest(
                        reader=reader.__module__, kind=kind, offset_kind=type(offset), offset=repr(offset)
                    ):
                        self.assertEqual(outcome(legacy_tile_text, data, offset), outcome(reader, data, offset))


if __name__ == "__main__":
    unittest.main()
