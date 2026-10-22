from __future__ import annotations

import unittest
from pathlib import Path
from scripts.make_interface import make_text


ROOT = Path(__file__).resolve().parents[1]


class TraceContractTests(unittest.TestCase):
    def test_breakpoint_trace_retains_emulator_termination_workaround(self) -> None:
        makefile = make_text(ROOT)
        trace_recipe = makefile.split("# Binary trace CPU execution", 1)[0].rsplit(".PHONY: trace", 1)[1]

        self.assertIn("-screenshot-interval 2147483647", trace_recipe)
        self.assertIn("-screenshot-dir build", trace_recipe)
        self.assertIn("-turbo -frameskip 8 -nosound", trace_recipe)
        self.assertIn(
            "$(if $(MAX_FRAMES_$(MOVIE)),-max-frames $(MAX_FRAMES_$(MOVIE)),)",
            trace_recipe,
        )


if __name__ == "__main__":
    unittest.main()
