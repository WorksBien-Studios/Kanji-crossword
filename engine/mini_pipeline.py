# -*- coding: utf-8 -*-
"""Generate the compact puzzle library used by the YouTube Playables game.

These are short chains (7-9 two-kanji words, so 8-10 kanji) that fit a 4x5 to 5x6 board and an
8-10 key tray. They reuse the same vocabulary, layout generator, starter computation and
exhaustive uniqueness check as the main release, but write to content/mini/ and never touch
content/puzzles-v2.json or its manifest.

    python3 engine/mini_pipeline.py            # regenerate content/mini/puzzles-mini.json
    python3 engine/mini_pipeline.py --check    # validate the committed file
"""
from __future__ import annotations

import argparse
import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fast_tree import build_pos_index2, fast_starters_for_chain  # noqa: E402
from final_pipeline import _base_record, _verify_unique, numbering_for  # noqa: E402
from partition import partition_all  # noqa: E402
from schema_v2 import assign_difficulty_bands, content_id, validation_digest  # noqa: E402
from vocab3 import READING, WORDS2, WORDS_BY_LEN  # noqa: E402

MODE = "kanjiNankuroMini"
MINI_SEED = 2026
# (words per puzzle, puzzle count). A chain of w words has w + 1 cells, so 8-10 kanji.
SIZES = [(7, 120), (8, 72), (9, 48)]
MAX_DIM = 6
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "content", "mini", "puzzles-mini.json")


def build_record(occupied, slots, word_records):
    cell_to_num, num_to_kanji = numbering_for(occupied)
    tray = set(occupied.values())
    restricted2 = [w for w in WORDS_BY_LEN[2] if set(w) <= tray]
    starters, _, _ = fast_starters_for_chain(
        word_records, occupied, cell_to_num, build_pos_index2(restricted2)
    )
    record = _base_record(occupied, word_records, cell_to_num, num_to_kanji, starters, restricted2)
    _verify_unique(record, slots, cell_to_num, restricted2)
    record["mode"] = MODE
    record["id"] = content_id(record)
    shuffled = list(num_to_kanji.values())
    random.Random(record["id"]).shuffle(shuffled)
    record["traySeed"] = shuffled
    return record


def generate():
    remaining = list(WORDS2)
    records = []
    for index, (words, count) in enumerate(SIZES):
        puzzles, remaining = partition_all(
            remaining,
            min_words=words,
            max_words=words,
            seed=MINI_SEED + index,
            max_puzzles=count,
            max_consecutive_stalls=3000,
        )
        if len(puzzles) != count:
            raise RuntimeError(f"needed {count} puzzles of {words} words; generated {len(puzzles)}")
        for occupied, slots, word_records in puzzles:
            records.append(build_record(occupied, slots, word_records))
    assign_difficulty_bands(records)
    for record in records:
        record["validationDigest"] = validation_digest(record)
    validate(records)
    return records


def validate(records):
    errors = []
    seen_ids, seen_words = set(), set()
    for rec in records:
        rid = rec.get("id", "?")
        if rec["mode"] != MODE:
            errors.append(f"{rid}: wrong mode")
        if rid in seen_ids:
            errors.append(f"{rid}: duplicate id")
        seen_ids.add(rid)
        if rid != content_id(rec):
            errors.append(f"{rid}: content-addressed id mismatch")
        if rec["validationDigest"] != validation_digest(rec):
            errors.append(f"{rid}: digest mismatch")
        if max(rec["rows"], rec["columns"]) > MAX_DIM:
            errors.append(f"{rid}: board larger than {MAX_DIM}x{MAX_DIM}")
        nums = sorted(int(n) for n in rec["solution"])
        if nums != list(range(1, len(nums) + 1)):
            errors.append(f"{rid}: slot numbers are not 1..N")
        if sorted(rec["traySeed"]) != sorted(rec["solution"].values()):
            errors.append(f"{rid}: tray does not match the solution")
        if len(set(rec["solution"].values())) != len(rec["solution"]):
            errors.append(f"{rid}: a kanji is mapped to two numbers")
        for num, kanji in rec["starterCells"].items():
            if rec["solution"].get(num) != kanji:
                errors.append(f"{rid}: starter {num} disagrees with the solution")
        if not rec["starterCells"]:
            errors.append(f"{rid}: no starter cells")
        for span in rec["wordSpans"]:
            word = span["word"]
            if word in seen_words:
                errors.append(f"{rid}: word reused across puzzles: {word}")
            seen_words.add(word)
            if word not in READING or span["reading"] != READING[word]:
                errors.append(f"{rid}: unverified word or reading: {word}")
        # Re-solve exhaustively with the independent solver.
        occupied = {}
        for key, num in rec["cellNumbers"].items():
            r, c = (int(x) for x in key.split(","))
            occupied[(r, c)] = rec["solution"][str(num)]
        slots = [[tuple(int(x) for x in cell.split(",")) for cell in span["cells"]] for span in rec["wordSpans"]]
        cell_to_num = {(int(k.split(",")[0]), int(k.split(",")[1])): n for k, n in rec["cellNumbers"].items()}
        restricted2 = [w for w in WORDS_BY_LEN[2] if set(w) <= set(rec["solution"].values())]
        try:
            _verify_unique(rec, slots, cell_to_num, restricted2)
        except Exception as exc:  # noqa: BLE001
            errors.append(f"{rid}: {exc}")
    if errors:
        raise RuntimeError("mini library invalid:\n  " + "\n  ".join(errors[:20]))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="validate the committed file only")
    args = parser.parse_args()
    if args.check:
        with open(OUT, encoding="utf-8") as handle:
            records = json.load(handle)
        validate(records)
        print(f"mini library: {len(records)} puzzles valid")
        return
    records = generate()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(records, handle, ensure_ascii=False, indent=1)
        handle.write("\n")
    shapes = {}
    for rec in records:
        key = f"{rec['rows']}x{rec['columns']}/{len(rec['solution'])}"
        shapes[key] = shapes.get(key, 0) + 1
    print(f"wrote {len(records)} puzzles to {OUT}\nshapes: {shapes}")


if __name__ == "__main__":
    main()
