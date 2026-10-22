"""Real thread/GC lifecycle controls; no game, ROM or native capture."""

import gc
import os
from pathlib import Path
import sys
import threading
import unittest
from unittest import mock
import weakref

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from tk_test_lifetime import tk_main_thread_lifetime


class TkLifetimeControls(unittest.TestCase):
    def setUp(self):
        self.enabled = gc.isenabled()
        self.addCleanup(gc.enable if self.enabled else gc.disable)

    def test_foreign_allocations_cannot_automatically_finalize_an_owned_cycle(self):
        gc.enable()
        finalized, observed = [], []
        owner = threading.get_ident()

        class Cycle:
            def __init__(self):
                self.loop = self

            def __del__(self):
                finalized.append(threading.get_ident())

        with tk_main_thread_lifetime():
            value = Cycle()
            reference = weakref.ref(value)
            del value

            def allocate():
                observed.append((threading.get_ident(), gc.isenabled()))
                for _ in range(5000):
                    cycle = []
                    cycle.append(cycle)

            thread = threading.Thread(target=allocate)
            thread.start()
            thread.join(timeout=5)
            self.assertFalse(thread.is_alive())
            self.assertNotEqual(owner, observed[0][0])
            self.assertIs(False, observed[0][1])
            self.assertIsNotNone(reference())
            self.assertEqual([], finalized)
        self.assertIsNone(reference())
        self.assertEqual([owner], finalized)
        self.assertTrue(gc.isenabled())

    def test_nesting_body_failure_and_collection_failure_restore_original_gc_state(self):
        for enabled in (False, True):
            with self.subTest(enabled=enabled):
                (gc.enable if enabled else gc.disable)()
                failure = RuntimeError("unchanged body failure")
                with self.assertRaises(RuntimeError) as caught:
                    with tk_main_thread_lifetime():
                        with tk_main_thread_lifetime():
                            self.assertFalse(gc.isenabled())
                        self.assertFalse(gc.isenabled())
                        raise failure
                self.assertIs(failure, caught.exception)
                self.assertEqual(enabled, gc.isenabled())
                with mock.patch.object(gc, "collect", side_effect=failure):
                    with self.assertRaises(RuntimeError) as caught:
                        with tk_main_thread_lifetime():
                            self.assertFalse(gc.isenabled())
                self.assertIs(failure, caught.exception)
                self.assertEqual(enabled, gc.isenabled())

        errors = []

        def foreign():
            try:
                with tk_main_thread_lifetime():
                    errors.append("entered")
            except RuntimeError as error:
                errors.append(str(error))

        thread = threading.Thread(target=foreign)
        thread.start()
        thread.join(timeout=5)
        self.assertFalse(thread.is_alive())
        self.assertEqual(["real Tk tests require the process main thread"], errors)

    def test_actual_unittest_class_cleanup_precedes_collection_even_when_setup_fails(self):
        gc.enable()
        for fail in (False, True):
            with self.subTest(fail=fail):
                events = []

                class Cycle:
                    def __init__(self):
                        self.loop = self

                    def __del__(self):
                        events.append(("collected", threading.get_ident()))

                class Case(unittest.TestCase):
                    @classmethod
                    def setUpClass(cls):
                        cls.enterClassContext(tk_main_thread_lifetime())
                        cls.addClassCleanup(lambda: events.append("ordinary cleanup"))
                        value = Cycle()
                        del value
                        if fail:
                            raise RuntimeError("fixture failure remains an error")

                    def test_one(self):
                        self.assertFalse(gc.isenabled())

                result = unittest.TestResult()
                unittest.defaultTestLoader.loadTestsFromTestCase(Case).run(result)
                self.assertEqual(int(not fail), result.testsRun)
                self.assertEqual(int(fail), len(result.errors))
                self.assertEqual([], result.skipped)
                self.assertEqual(["ordinary cleanup", ("collected", threading.get_ident())], events)
                self.assertTrue(gc.isenabled())

    def test_real_destroyed_tk_variables_and_images_close_without_foreign_unraisables(self):
        import tkinter as tk

        failures = []
        with tk_main_thread_lifetime(), mock.patch.object(sys, "unraisablehook", side_effect=failures.append):

            def create_destroyed_owner():
                try:
                    root = tk.Tk()
                    root.withdraw()
                except tk.TclError as error:
                    if os.name == "nt":
                        raise
                    self.skipTest(str(error))

                class Owner:
                    pass

                owner = Owner()
                owner.loop, owner.root = owner, root
                owner.variable = tk.StringVar(master=root, value="owned")
                owner.image = tk.PhotoImage(master=root, width=1, height=1)
                reference = weakref.ref(root)
                root.destroy()
                return reference

            reference = create_destroyed_owner()

            def allocate():
                for _ in range(5000):
                    cycle = []
                    cycle.append(cycle)

            thread = threading.Thread(target=allocate)
            thread.start()
            thread.join(timeout=5)
            self.assertFalse(thread.is_alive())
            self.assertIsNotNone(reference())
            # Collect explicitly before leaving the unraisable-hook observer.
            gc.collect()
            self.assertIsNone(reference())
            self.assertEqual([], failures)


if __name__ == "__main__":
    unittest.main()
