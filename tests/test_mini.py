# -*- coding: utf-8 -*-
import json
import os
import sys
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENGINE = os.path.join(ROOT, "engine")
if ENGINE not in sys.path:
    sys.path.insert(0, ENGINE)

import mini_pipeline  # noqa: E402


class MiniLibraryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(mini_pipeline.OUT, encoding="utf-8") as handle:
            cls.records = json.load(handle)

    def test_library_validates_exhaustively(self):
        mini_pipeline.validate(self.records)

    def test_sizes_fit_the_small_board(self):
        self.assertEqual(len(self.records), 240)
        for rec in self.records:
            self.assertLessEqual(max(rec["rows"], rec["columns"]), mini_pipeline.MAX_DIM)
            self.assertLessEqual(len(rec["solution"]), 10)
            self.assertGreaterEqual(len(rec["solution"]), 7)

    def test_all_four_bands_present(self):
        self.assertEqual({rec["difficulty"] for rec in self.records}, {"easy", "standard", "hard", "expert"})

    def test_main_release_is_untouched_by_mini_mode(self):
        with open(os.path.join(ROOT, "content", "puzzles-v2.json"), encoding="utf-8") as handle:
            main = json.load(handle)
        self.assertEqual(len(main), 360)
        self.assertNotIn(mini_pipeline.MODE, {rec["mode"] for rec in main})


if __name__ == "__main__":
    unittest.main()
