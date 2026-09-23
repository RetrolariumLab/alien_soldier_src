"""Tiny exact-output controls for the LZSS match-chain frontier."""

from __future__ import annotations

import random
import struct
import sys
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import lzss_codec as codec
from authoring.lzss_codec import (
    BLOCK, MAX_LITERAL, MAX_MATCH, MAX_REPEAT, MIN_MATCH, alternating_run,
    build_chains, longest_match, pair_run, run_length)


def legacy_parse_block(data):
    """Frozen pre-frontier parse_block; helpers and emission are unchanged."""
    size = len(data)
    heads, previous = build_chains(data)
    matches = [(0, 0)] * size
    for at in range(size):
        matches[at] = longest_match(data, at, min(MAX_MATCH, size - at),
                                    heads, previous)

    cost = [0] * (size + 1)
    choice = [None] * (size + 1)
    for at in range(size - 1, -1, -1):
        left = size - at
        best = 2 + cost[at + 1]
        pick = ("literal", 1, None)

        for length in range(2, min(MAX_LITERAL, left) + 1):
            here = 1 + length + cost[at + length]
            if here < best:
                best, pick = here, ("literal", length, None)

        repeats = run_length(data, at, min(MAX_REPEAT, left))
        for length in range(MIN_MATCH, repeats + 1):
            here = 2 + cost[at + length]
            if here < best:
                best, pick = here, ("run", length, data[at])

        if left >= 4:
            for count in range(2, pair_run(data, at, left) + 1):
                here = 3 + cost[at + count * 2]
                if here < best:
                    best, pick = here, ("pair", count * 2, data[at:at + 2])
            for count in range(2, alternating_run(data, at, left) + 1):
                here = 2 + count + cost[at + count * 2]
                if here < best:
                    best, pick = here, ("alternate", count * 2, data[at])

        length, distance = matches[at]
        for take in range(MIN_MATCH, length + 1):
            here = 2 + cost[at + take]
            if here < best:
                best, pick = here, ("match", take, distance)
        cost[at] = best
        choice[at] = pick

    tokens = []
    at = 0
    while at < size:
        kind, length, detail = choice[at]
        tokens.append((kind, length, detail))
        at += length
    return tokens


def legacy_parse(data):
    tokens = []
    for start in range(0, len(data), BLOCK):
        tokens.extend(legacy_parse_block(data[start:start + BLOCK]))
    return tokens


def legacy_compress(data, tokens):
    if not data:
        raise ValueError("there is nothing to compress")
    body = codec.emit_blocks(data, tokens)
    payload = struct.pack(">H", len(body)) + body
    return payload if len(payload) % 2 == 0 else payload + bytes(1)


class ObservedSequence:
    def __init__(self, data):
        self.data = data
        self.reads = []

    def __len__(self):
        self.reads.append(("len",))
        return len(self.data)

    def __getitem__(self, index):
        self.reads.append(("get", index))
        return self.data[index]


class ObservedBytes(bytes):
    def __new__(cls, data):
        instance = super().__new__(cls, data)
        instance.reads = []
        return instance

    def __len__(self):
        self.reads.append(("len",))
        return super().__len__()

    def __getitem__(self, index):
        self.reads.append(("get", index))
        return super().__getitem__(index)


class ObservedBytearray(bytearray):
    def __init__(self, data):
        super().__init__(data)
        self.reads = []

    def __len__(self):
        self.reads.append(("len",))
        return super().__len__()

    def __getitem__(self, index):
        self.reads.append(("get", index))
        return super().__getitem__(index)


class LZSSMatchFrontierTests(unittest.TestCase):
    def assert_legacy_identity(self, data):
        expected = legacy_parse(data)
        self.assertEqual(expected, codec.parse(data))
        if data:
            self.assertEqual(legacy_compress(data, expected), codec.compress(data))
        else:
            with self.assertRaisesRegex(ValueError, "there is nothing to compress"):
                codec.compress(data)
        if len(data) <= BLOCK:
            self.assertEqual(legacy_parse_block(data), codec.parse_block(data))

    def test_repeats_ties_overlap_and_short_inputs_keep_exact_tokens_and_bytes(self):
        tie = b"abXabYabZ"
        self.assertEqual((2, 3), longest_match(tie, 6, 3, *build_chains(tie)))
        samples = (
            b"", b"a", b"ab", b"aa", b"aaa", tie,
            b"A" * 129, b"AB" * 67, b"abc" * 45,
            b"a0a1a2a3a4a5" * 9,
            b"abcXabcYabcZabcXabcYabcZ",
            bytes(range(256)),
        )
        for sample in samples:
            for factory in (bytes, bytearray):
                with self.subTest(size=len(sample), factory=factory.__name__):
                    self.assert_legacy_identity(factory(sample))

    def test_seeded_low_alphabet_and_arbitrary_bytes_keep_exact_stream(self):
        randomizer = random.Random(0xA11E)
        for alphabet in (2, 7, 256):
            for size in (2, 3, 17, 32, 33, 64, 129, 257):
                sample = bytes(randomizer.randrange(alphabet) for _ in range(size))
                for factory in (bytes, bytearray):
                    with self.subTest(alphabet=alphabet, size=size,
                                      factory=factory.__name__):
                        self.assert_legacy_identity(factory(sample))

    def test_block_edges_keep_exact_independent_block_tokens_and_stream(self):
        source = bytes(range(251)) * 9
        for size in (BLOCK - 1, BLOCK, BLOCK + 1, 2 * BLOCK + 1):
            for factory in (bytes, bytearray):
                with self.subTest(size=size, factory=factory.__name__):
                    self.assert_legacy_identity(factory(source[:size]))

    def test_exact_builtin_frontiers_start_before_at_without_dropping_calls(self):
        sample = b"abXabYabZ" * 4
        for factory in (bytes, bytearray):
            data = factory(sample)
            calls = []

            def inspect_frontier(current, at, limit, heads, previous):
                calls.append(at)
                if at + 1 < len(current):
                    key = (current[at] << 8) | current[at + 1]
                    self.assertEqual(previous[at], heads.get(key, -1))
                    self.assertLess(heads[key], at)
                return longest_match(current, at, limit, heads, previous)

            with self.subTest(factory=factory.__name__):
                with mock.patch.object(codec, "longest_match", inspect_frontier):
                    actual = codec.parse_block(data)
                self.assertEqual(list(range(len(data))), calls)
                self.assertEqual(legacy_parse_block(data), actual)

    def test_other_sequences_and_subclasses_keep_legacy_data_read_order(self):
        sample = b"abXabYabZabcabcabc"
        for factory in (ObservedSequence, ObservedBytes, ObservedBytearray):
            old_data, new_data = factory(sample), factory(sample)
            expected = legacy_parse_block(old_data)
            actual = codec.parse_block(new_data)
            with self.subTest(factory=factory.__name__):
                self.assertEqual(expected, actual)
                self.assertEqual(old_data.reads, new_data.reads)


if __name__ == "__main__":
    unittest.main()
