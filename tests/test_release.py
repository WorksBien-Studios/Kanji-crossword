# -*- coding: utf-8 -*-
import copy
import json
import os
import sys
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENGINE = os.path.join(ROOT, "engine")
if ENGINE not in sys.path:
    sys.path.insert(0, ENGINE)

from release_validator import REQUIRED_FIELDS, _validate_record, validate_release
from schema_v2 import content_id, validation_digest

CONTENT = os.path.join(ROOT, "content")


class ReleaseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(os.path.join(CONTENT, "puzzles-v2.json"), encoding="utf-8") as handle:
            cls.puzzles = json.load(handle)
        with open(os.path.join(CONTENT, "manifest.json"), encoding="utf-8") as handle:
            cls.manifest = json.load(handle)

    def test_full_release_exhaustively_validates(self):
        summary = validate_release(CONTENT, exhaustive=True)
        self.assertEqual(summary["puzzles"], 360)

    def test_digest_tamper_is_rejected(self):
        record = copy.deepcopy(self.puzzles[0])
        number = next(iter(record["starterCells"]))
        record["starterCells"][number] = "偽"
        errors = _validate_record(record, set(), exhaustive=False)
        self.assertTrue(any("starter" in error or "validationDigest" in error for error in errors))

    def test_content_address_changes_with_gameplay(self):
        record = copy.deepcopy(self.puzzles[0])
        original = record["id"]
        cell = next(iter(record["cellNumbers"]))
        record["cellNumbers"][cell] += 10000
        self.assertNotEqual(content_id(record), original)

    def test_unknown_schema_field_is_rejected(self):
        record = copy.deepcopy(self.puzzles[0])
        record["surpriseField"] = True
        errors = _validate_record(record, set(), exhaustive=False)
        self.assertTrue(any("unknown" in error for error in errors))

    def test_manifest_matches_records(self):
        by_id = {entry["id"]: entry for entry in self.manifest}
        self.assertEqual(len(by_id), len(self.puzzles))
        for record in self.puzzles:
            self.assertEqual(by_id[record["id"]]["sha256"], validation_digest(record))

    def test_schema_is_exact(self):
        for record in self.puzzles:
            self.assertEqual(set(record), REQUIRED_FIELDS)


if __name__ == "__main__":
    unittest.main()
