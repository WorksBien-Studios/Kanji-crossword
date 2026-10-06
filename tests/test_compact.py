# -*- coding: utf-8 -*-
import json
import os
import sys
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENGINE = os.path.join(ROOT, "engine")
if ENGINE not in sys.path:
    sys.path.insert(0, ENGINE)

import compact_pipeline  # noqa: E402


class CompactLibraryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(compact_pipeline.OUT, encoding="utf-8") as handle:
            cls.records = json.load(handle)

    def test_library_validates_exhaustively(self):
        compact_pipeline.validate(self.records)

    def test_boards_are_dense_and_small(self):
        self.assertGreaterEqual(len(self.records), 100)
        for rec in self.records:
            self.assertLessEqual(max(rec["rows"], rec["columns"]), 5)
            self.assertIn(len(rec["solution"]), (7, 8))
            # Repeated kanji share a number, so there are clearly more cells than numbers.
            self.assertGreaterEqual(len(rec["cellNumbers"]), len(rec["solution"]) + 6)

    def test_all_four_bands_present(self):
        self.assertEqual({rec["difficulty"] for rec in self.records}, {"easy", "standard", "hard", "expert"})

    def test_solver_is_not_fooled_by_a_fake_word(self):
        # A grid whose slot spells a non-word must not validate (the raw solver would accept it).
        rec = json.loads(json.dumps(self.records[0]))
        span = rec["wordSpans"][0]
        span["word"] = span["word"][0] * len(span["word"])
        rec["validationDigest"] = compact_pipeline.validation_digest(rec)
        with self.assertRaises(RuntimeError):
            compact_pipeline.validate([rec])

    def test_main_release_is_untouched(self):
        with open(os.path.join(ROOT, "content", "puzzles-v2.json"), encoding="utf-8") as handle:
            main = json.load(handle)
        self.assertEqual(len(main), 360)
        self.assertNotIn(compact_pipeline.MODE, {rec["mode"] for rec in main})


if __name__ == "__main__":
    unittest.main()
