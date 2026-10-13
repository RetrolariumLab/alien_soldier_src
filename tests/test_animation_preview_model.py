from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import animation_preview_model as model
from authoring.sprite_mapping_model import SpritePiece


VISIBLE = model.CallerState(0xE0)


def geometry(name: str, x: int = -4, y: int = -8, dynamic: bool = False):
    return model.FrameGeometry(name, (SpritePiece(0x8001, 5, 0, y, x,
                                                "Art" if dynamic else ""),), "fixture.s")


def looping():
    return model.Catalog({"Loop": (model.Entry("A", 3), model.Entry("B", 2), model.Entry("Loop", 0))},
                         {"A": geometry("A"), "B": geometry("B", 3, 2)}, {})


def reader_fixture(root: Path):
    path = root / model.SOURCE
    path.parent.mkdir(parents=True)
    caller_operations = model._operations((ROOT / model.SOURCE).read_text(encoding="utf-8"),
                                          "Sprite_RenderObjectList", "; End of function Sprite_RenderObjectList")
    caller = ("Sprite_RenderObjectList:\n" + "\n".join(caller_operations)
              + "\n; End of function Sprite_RenderObjectList\n")
    timed = ("Anim_ResolveTimedMappingFrame:\n"
             + "\n".join(model.workspace.TIMED_READER_OPERATIONS)
             + "\n; End of function Anim_ResolveTimedMappingFrame\n")
    path.write_text(caller + timed, encoding="utf-8")
    return path


class TemporalTests(unittest.TestCase):
    def test_initial_load_countdown_transition_and_one_relative_loop(self):
        initial = model.PlaybackState(model.Cursor("Loop"))
        observed = model.simulate(looping(), initial, VISIBLE, 8)
        self.assertEqual(["A", "A", "A", "B", "B", "A", "A", "A"],
                         [item.geometry.symbol for item in observed])
        self.assertEqual([3, 2, 1, 2, 1, 3, 2, 1], [item.after.timer for item in observed])
        self.assertEqual("load-current-entry-timer", observed[0].event)
        self.assertEqual("next-timed-entry", observed[3].event)
        self.assertEqual("one-relative-jump", observed[5].event)
        self.assertEqual(model.Cursor("Loop", 2), observed[5].jump_entry)
        self.assertEqual(0, initial.timer)

    def test_every_selected_mapping_has_real_piece_geometry(self):
        observed = model.simulate(looping(), model.PlaybackState(model.Cursor("Loop")), VISIBLE, 4)
        self.assertEqual((-4, -8, 16, 16), observed[0].geometry.bounds)
        self.assertEqual((3, 2, 16, 16), observed[3].geometry.bounds)
        piece = observed[3].document()["mapping"]["pieces"][0]
        self.assertEqual((3, 2, 1, 16, 16),
                         tuple(piece[key] for key in ("x", "y", "tile_offset", "width", "height")))
        self.assertFalse(observed[3].document()["native_run"])
        self.assertFalse(observed[3].document()["runtime_fidelity_verified"])

    def test_negative_low_byte_controls_hold_without_timer_or_cursor_writes(self):
        for timer in (0x80, 0xFF, 0x0180, 0xFFFF):
            initial = model.PlaybackState(model.Cursor("Loop"), timer)
            observed = model.step(looping(), initial, VISIBLE)
            self.assertEqual(initial, observed.after)
            self.assertEqual("hold-negative-low-byte", observed.event)
            self.assertFalse(observed.timer_written)
            self.assertFalse(observed.cursor_written)

    def test_ff_source_duration_is_an_indefinite_control_not_255_calls(self):
        catalog = model.Catalog({"Hold": (model.Entry("A", 0xFF),)}, {"A": geometry("A")}, {})
        observed = model.simulate(catalog, model.PlaybackState(model.Cursor("Hold")), VISIBLE, 300)
        self.assertTrue(all(item.after.timer == 255 for item in observed))
        self.assertTrue(all(item.event == "hold-negative-low-byte" for item in observed[1:]))

    def test_low_zero_reloads_even_when_the_full_word_is_not_zero(self):
        initial = model.PlaybackState(model.Cursor("Loop"), 0x0100)
        observed = model.step(looping(), initial, model.CallerState(0xE0, 0x80))
        self.assertEqual(3, observed.after.timer)
        self.assertEqual("load-current-entry-timer", observed.event)
        self.assertTrue(observed.cursor_written)

    def test_word_countdown_and_next_low_byte_reload_are_not_a_naive_duration(self):
        first = model.step(looping(), model.PlaybackState(model.Cursor("Loop"), 0x0101), VISIBLE)
        self.assertEqual(0x0100, first.after.timer)
        second = model.step(looping(), first.after, VISIBLE)
        self.assertEqual(3, second.after.timer)

    def test_frame_control_bit7_holds_countdown_but_does_not_prevent_initial_load(self):
        caller = model.CallerState(0xE0, 0x80)
        observed = model.simulate(looping(), model.PlaybackState(model.Cursor("Loop")), caller, 8)
        self.assertEqual("load-current-entry-timer", observed[0].event)
        self.assertTrue(all(item.after.timer == 3 for item in observed))
        self.assertTrue(all(item.event == "paused-countdown" for item in observed[1:]))
        self.assertTrue(all(item.timer_written and not item.cursor_written for item in observed[1:]))
        self.assertEqual(2, model.step(looping(), observed[-1].after, model.CallerState(0xE0, 0x40)).after.timer)

    def test_advance_only_route_resolves_but_does_not_claim_a_rendered_sprite(self):
        observed = model.step(looping(), model.PlaybackState(model.Cursor("Loop")), model.CallerState(0x60))
        self.assertEqual("A", observed.geometry.symbol)
        self.assertFalse(observed.render_route_selected)
        self.assertFalse(observed.document()["mapping_render_route_selected"])

    def test_direct_inactive_and_single_piece_callers_are_explicitly_unsupported(self):
        for flags in (0, 0x20, 0x40, 0x80, 0xA0, 0xC0):
            with self.assertRaisesRegex(model.UnsupportedPlayback, "do not select"):
                model.step(looping(), model.PlaybackState(model.Cursor("Loop")), model.CallerState(flags))

    def test_other_readers_are_not_selected_by_a_matching_numeric_flag_byte(self):
        for consumer in ("player-dynamic", "byte-offset-reader", "unknown", None):
            with self.assertRaisesRegex(model.UnsupportedPlayback, "unsupported animation reader"):
                model.step(looping(), model.PlaybackState(model.Cursor("Loop")),
                           model.CallerState(0xE0, consumer_path=consumer))

    def test_linear_end_is_not_an_invented_stop_or_loop(self):
        catalog = model.Catalog({"Linear": (model.Entry("A", 1),)}, {"A": geometry("A")}, {})
        first = model.step(catalog, model.PlaybackState(model.Cursor("Linear")), VISIBLE)
        with self.assertRaisesRegex(model.UnsupportedPlayback, "unproved script fall-through"):
            model.step(catalog, first.after, VISIBLE)

    def test_a_caller_cannot_start_on_a_jump_record(self):
        with self.assertRaisesRegex(model.UnsupportedPlayback, "starts on a jump"):
            model.step(looping(), model.PlaybackState(model.Cursor("Loop", 2)), VISIBLE)

    def test_dynamic_piece_format_is_not_consumed_as_a_static_timed_mapping(self):
        catalog = model.Catalog({"Dynamic": (model.Entry("A", 1),)}, {"A": geometry("A", dynamic=True)}, {})
        with self.assertRaisesRegex(model.UnsupportedPlayback, "eight-byte dynamic"):
            model.step(catalog, model.PlaybackState(model.Cursor("Dynamic")), VISIBLE)


class DomainTests(unittest.TestCase):
    def test_missing_mappings_and_jump_destinations_fail_before_playback(self):
        for entries in ((model.Entry("MissingMapping", 1),),
                        (model.Entry("A", 1), model.Entry("MissingScript", 0))):
            with self.assertRaisesRegex(ValueError, "missing"):
                model.Catalog({"Script": entries}, {"A": geometry("A")}, {})

    def test_malformed_destination_entries_are_rejected_before_graph_inspection(self):
        with self.assertRaisesRegex(ValueError, "entry target is malformed"):
            model.Catalog({"Script": (model.Entry("Destination", 0),),
                           "Destination": ("not an entry",)}, {"A": geometry("A")}, {})

    def test_zero_duration_cycle_or_chain_is_not_recursively_resolved(self):
        for scripts in (
                {"A": (model.Entry("B", 0),), "B": (model.Entry("A", 0),)},
                {"A": (model.Entry("B", 0),), "B": (model.Entry("C", 0),),
                 "C": (model.Entry("Frame", 1),)}):
            with self.assertRaisesRegex(model.UnsupportedPlayback, "jump chain/cycle"):
                model.Catalog(scripts, {"Frame": geometry("Frame")}, {})

    def test_normal_mapping_loops_are_finite_bounded_preview_inputs(self):
        self.assertEqual(model.MAX_STEPS, len(model.simulate(
            looping(), model.PlaybackState(model.Cursor("Loop")), VISIBLE, model.MAX_STEPS)))
        for steps in (-1, model.MAX_STEPS + 1, True, 1.0):
            with self.assertRaisesRegex(ValueError, "invocation count"):
                model.simulate(looping(), model.PlaybackState(model.Cursor("Loop")), VISIBLE, steps)

    def test_empty_trajectory_still_validates_its_caller_and_state(self):
        self.assertEqual((), model.simulate(looping(), model.PlaybackState(model.Cursor("Loop")), VISIBLE, 0))
        with self.assertRaisesRegex(model.UnsupportedPlayback, "do not select"):
            model.simulate(looping(), model.PlaybackState(model.Cursor("Loop")), model.CallerState(0), 0)
        with self.assertRaisesRegex(ValueError, "timer"):
            model.simulate(looping(), model.PlaybackState(model.Cursor("Loop"), True), VISIBLE, 0)

    def test_typed_timer_cursor_and_flags_are_not_coerced(self):
        for initial in (model.PlaybackState(model.Cursor("Loop"), True),
                        model.PlaybackState(model.Cursor("Loop"), -1),
                        model.PlaybackState(model.Cursor("Loop", False)),
                        model.PlaybackState(model.Cursor("Missing")),
                        model.PlaybackState(model.Cursor("Loop", 100))):
            with self.assertRaises(ValueError):
                model.step(looping(), initial, VISIBLE)
        for caller in (model.CallerState(True), model.CallerState(0xE0, 1.0), {}):
            with self.assertRaises(ValueError):
                model.step(looping(), model.PlaybackState(model.Cursor("Loop")), caller)

    def test_inventory_is_a_snapshot_not_a_mutable_caller_alias(self):
        scripts = {"Script": [model.Entry("A", 1)]}
        mappings = {"A": geometry("A")}
        catalog = model.Catalog(scripts, mappings, {})
        scripts["Script"][0] = model.Entry("Missing", 1)
        mappings.clear()
        self.assertEqual("A", model.step(catalog, model.PlaybackState(model.Cursor("Script")), VISIBLE).geometry.symbol)
        with self.assertRaises(TypeError):
            catalog.scripts["New"] = ()

    def test_mapping_pieces_keep_typed_source_terminators_and_bounds(self):
        for piece in (SpritePiece(1, 5, 0, 0, 0), SpritePiece(0x8000, 5, 0, 0, 128),
                      SpritePiece(True, 5, 0, 0, 0)):
            with self.assertRaises(ValueError):
                model.Catalog({"Script": (model.Entry("A", 1),)},
                              {"A": model.FrameGeometry("A", (piece,))}, {})


class ReaderProofTests(unittest.TestCase):
    def test_complete_source_reader_and_caller_proof_stays_source_only(self):
        proof = model.prove_reader(ROOT)
        self.assertTrue(proof["source_reader_verified"])
        self.assertTrue(proof["source_caller_verified"])
        self.assertEqual(64, len(proof["source_sha256"]))
        self.assertFalse(proof["compiled_reader_verified"])
        self.assertFalse(proof["native_run"])
        self.assertFalse(proof["runtime_fidelity_verified"])

    def test_reader_clock_and_caller_mutations_or_comment_substitutes_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = reader_fixture(root)
            original = path.read_text(encoding="utf-8")
            model.prove_reader(root)
            for before, after in (("tst.b d0", "tst.w d0"),
                                  ("subq.w #1,d0", "; subq.w #1,d0"),
                                  ("ror.l #8,d3", "ror.l #16,d3"),
                                  ("ror.l #8,d3", "ror.l #8,d3\n move.l #0,d3"),
                                  ("bsr.w Anim_ResolveTimedMappingFrame", "nop"),
                                  ("pea Sprite_RenderObjectList_NextObject(pc)", "nop")):
                path.write_text(original.replace(before, after), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "operations changed"):
                    model.prove_reader(root)


class CanonicalTrajectoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogs = {profile: model.build_catalog(ROOT, profile) for profile in ("jp", "eu")}

    def test_all_exact_targets_include_the_two_previously_name_filtered_bugmax_frames(self):
        for profile, catalog in self.catalogs.items():
            self.assertEqual(112, len(catalog.scripts))
            self.assertEqual(670, sum(map(len, catalog.scripts.values())))
            self.assertEqual(272, len(catalog.mappings))
            self.assertIn("Projectile_BugmaxSpreadFrame00", catalog.mappings)
            self.assertIn("Projectile_BugmaxSpreadFrame01", catalog.mappings)
            self.assertEqual(profile, catalog.proof["profile"])

    def test_bird_cycle_has_independently_fixed_thirty_invocation_period(self):
        expected = []
        for frame, duration in ((0, 4), (1, 3), (2, 2), (3, 1), (4, 2), (5, 3),
                                (6, 4), (5, 3), (4, 2), (3, 1), (2, 2), (1, 3)):
            expected.extend(["Enemy_BirdSpriteMapping%02d" % frame] * duration)
        self.assertEqual(30, len(expected))
        for catalog in self.catalogs.values():
            observed = model.simulate(catalog, model.PlaybackState(model.Cursor("Enemy_BirdAnimation00")), VISIBLE, 60)
            self.assertEqual(expected * 2, [item.geometry.symbol for item in observed])
            self.assertEqual("one-relative-jump", observed[30].event)
            self.assertEqual(26, observed[0].geometry.pieces[0].y)
            self.assertEqual(25, observed[4].geometry.pieces[0].y)
            self.assertEqual(6, len(observed[0].geometry.pieces))

    def test_shared_combat_script_reaches_its_real_ff_terminal_hold(self):
        for catalog in self.catalogs.values():
            observed = model.simulate(catalog, model.PlaybackState(model.Cursor("SharedCombatSpriteAnimation00")), VISIBLE, 80)
            self.assertEqual(8, observed[16].after.cursor.index)
            self.assertEqual("SharedCombatSpriteFrame05", observed[16].geometry.symbol)
            self.assertEqual(255, observed[16].after.timer)
            self.assertTrue(all(item.event == "hold-negative-low-byte" for item in observed[17:]))

    def test_every_canonical_script_has_bounded_source_temporal_piece_output(self):
        for catalog in self.catalogs.values():
            for name in catalog.scripts:
                observed = model.simulate(catalog, model.PlaybackState(model.Cursor(name)), VISIBLE, 64)
                self.assertEqual(64, len(observed))
                self.assertTrue(all(item.geometry.pieces and item.geometry.source_path for item in observed))
                self.assertTrue(all(not item.geometry.dynamic for item in observed))

    def test_ordinary_duration_edit_changes_the_preview_without_becoming_native_evidence(self):
        document = model.workspace.export_document(ROOT, "jp")
        record = next(item for item in document["scripts"] if item["name"] == "Enemy_BirdAnimation00")
        record["frames"][0]["duration"] = 5
        edited = model.build_catalog(ROOT, "jp", document)
        initial = model.PlaybackState(model.Cursor("Enemy_BirdAnimation00"))
        original_steps = model.simulate(self.catalogs["jp"], initial, VISIBLE, 6)
        edited_steps = model.simulate(edited, initial, VISIBLE, 6)
        self.assertEqual("Enemy_BirdSpriteMapping01", original_steps[4].geometry.symbol)
        self.assertEqual("Enemy_BirdSpriteMapping00", edited_steps[4].geometry.symbol)
        self.assertEqual("Enemy_BirdSpriteMapping01", edited_steps[5].geometry.symbol)
        self.assertFalse(edited.proof["runtime_fidelity_verified"])


if __name__ == "__main__":
    unittest.main()
