# -*- coding: utf-8 -*-
"""Generate, verify and emit the canonical offline puzzle library."""
from __future__ import annotations

import argparse
import json
import os
import random
import time

from csp import Solver
from difficulty import compute_difficulty
from fast_tree import build_pos_index2, fast_starters_for_chain
from partition import partition_all
from schema_v2 import (
    SCHEMA_VERSION,
    assign_difficulty_bands,
    content_id,
    mode_for_word_count,
    validation_digest,
)
from vocab3 import DICTIONARY_ATTRIBUTION, READING, WORDS2, WORDS_BY_LEN

TARGET_PUZZLES = 360
STANDARD_PUZZLES = 240
LARGE_PUZZLES = 120
STANDARD_MIN_WORDS = 12
STANDARD_MAX_WORDS = 18
LARGE_MIN_WORDS = 20
LARGE_MAX_WORDS = 24
PARTITION_SEED = 42


def numbering_for(occupied):
    kanji_to_num = {}
    cell_to_num = {}
    for cell in sorted(occupied.keys()):
        value = occupied[cell]
        if value not in kanji_to_num:
            kanji_to_num[value] = len(kanji_to_num) + 1
        cell_to_num[cell] = kanji_to_num[value]
    return cell_to_num, {num: kanji for kanji, num in kanji_to_num.items()}


def _base_record(occupied, records, cell_to_num, num_to_kanji, starters, restricted2):
    rows = [r for r, _ in occupied]
    cols = [c for _, c in occupied]
    rmin, rmax = min(rows), max(rows)
    cmin, cmax = min(cols), max(cols)
    nrows, ncols = rmax - rmin + 1, cmax - cmin + 1

    layout = [["#"] * ncols for _ in range(nrows)]
    cell_numbers = {}
    for (r, c), num in cell_to_num.items():
        rr, cc = r - rmin, c - cmin
        layout[rr][cc] = "."
        cell_numbers[f"{rr},{cc}"] = num

    word_spans = []
    for word, cells in records:
        shifted = [f"{r-rmin},{c-cmin}" for r, c in cells]
        word_spans.append(
            {"word": word, "reading": READING[word], "cells": shifted}
        )

    score, metrics = compute_difficulty(records, cell_to_num, starters, restricted2)
    record = {
        "schemaVersion": SCHEMA_VERSION,
        "mode": mode_for_word_count(len(records)),
        "difficulty": "unassigned",
        "difficultyScore": score,
        "difficultyMetrics": metrics,
        "rows": nrows,
        "columns": ncols,
        "cellLayout": layout,
        "cellNumbers": cell_numbers,
        "solution": {str(num): kanji for num, kanji in num_to_kanji.items()},
        "starterCells": {str(num): kanji for num, kanji in starters.items()},
        "wordSpans": word_spans,
        "editorialStatus": "ai_review_passed_owner_approved",
        "editorialNotes": (
            "Automated JMdict common-word/POS filtering plus project review. "
            "AI-assisted localisation/content review was performed and approved "
            "by the project owner; this field does not claim native-linguist sign-off."
        ),
        "sourceNotes": DICTIONARY_ATTRIBUTION,
    }
    record["id"] = content_id(record)
    tray = list(num_to_kanji.values())
    random.Random(record["id"]).shuffle(tray)
    record["traySeed"] = tray
    return record


def _verify_unique(record, slots, cell_to_num, restricted2):
    solver = Solver(slots, {2: restricted2})
    solver_starters = {int(num): kanji for num, kanji in record["starterCells"].items()}
    solutions = solver.count_with_numbering(
        cell_to_num, solver_starters, cap=2, forbid_repeat=False
    )
    if len(solutions) != 1:
        raise RuntimeError(
            f"{record['id']} is not uniquely solvable: {len(solutions)} solutions"
        )
    solved = solutions[0]
    for cell, number in cell_to_num.items():
        expected = record["solution"][str(number)]
        if solved.get(cell) != expected:
            raise RuntimeError(
                f"{record['id']} solver mismatch at {cell}: "
                f"{solved.get(cell)!r} != {expected!r}"
            )


def generate_library():
    started = time.time()
    large, remaining = partition_all(
        WORDS2,
        min_words=LARGE_MIN_WORDS,
        max_words=LARGE_MAX_WORDS,
        seed=PARTITION_SEED,
        max_puzzles=LARGE_PUZZLES,
        max_consecutive_stalls=3000,
    )
    if len(large) != LARGE_PUZZLES:
        raise RuntimeError(
            f"release requires {LARGE_PUZZLES} large puzzles; generated {len(large)}"
        )

    standard, remaining = partition_all(
        remaining,
        min_words=STANDARD_MIN_WORDS,
        max_words=STANDARD_MAX_WORDS,
        seed=PARTITION_SEED + 1,
        max_puzzles=STANDARD_PUZZLES,
        max_consecutive_stalls=3000,
    )
    if len(standard) != STANDARD_PUZZLES:
        raise RuntimeError(
            f"release requires {STANDARD_PUZZLES} standard puzzles; generated {len(standard)}"
        )

    puzzles = standard + large
    if len(puzzles) != TARGET_PUZZLES:
        raise RuntimeError(
            f"release requires exactly {TARGET_PUZZLES} puzzles; generated {len(puzzles)}"
        )

    records = []
    seen_words = set()
    for occupied, slots, word_records in puzzles:
        words_here = [word for word, _ in word_records]
        overlap = seen_words.intersection(words_here)
        if overlap:
            raise RuntimeError(f"cross-puzzle word reuse: {sorted(overlap)[:5]}")
        seen_words.update(words_here)

        cell_to_num, num_to_kanji = numbering_for(occupied)
        tray = set(occupied.values())
        restricted2 = [word for word in WORDS_BY_LEN[2] if set(word) <= tray]
        by_pos2 = build_pos_index2(restricted2)
        starters, _, _ = fast_starters_for_chain(
            word_records, occupied, cell_to_num, by_pos2
        )
        record = _base_record(
            occupied,
            word_records,
            cell_to_num,
            num_to_kanji,
            starters,
            restricted2,
        )
        _verify_unique(record, slots, cell_to_num, restricted2)
        records.append(record)

    if len({record["id"] for record in records}) != len(records):
        raise RuntimeError("content-addressed ID collision")

    assign_difficulty_bands(records)
    for record in records:
        record["validationDigest"] = validation_digest(record)

    print(
        f"generated and exhaustively verified {len(records)} puzzles in "
        f"{time.time()-started:.1f}s; remaining vocabulary={len(remaining)}"
    )
    return records


def write_outputs(records, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    full_path = os.path.join(output_dir, "puzzles-v2.json")
    sample_path = os.path.join(output_dir, "puzzles-v2-sample.json")
    manifest_path = os.path.join(output_dir, "manifest.json")

    with open(full_path, "w", encoding="utf-8") as handle:
        json.dump(records, handle, ensure_ascii=False, indent=1)
        handle.write("\n")

    sample_indexes = sorted(
        {0, len(records) // 4, len(records) // 2, 3 * len(records) // 4, len(records) - 1}
    )
    with open(sample_path, "w", encoding="utf-8") as handle:
        json.dump([records[i] for i in sample_indexes], handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    manifest = [
        {
            "schemaVersion": record["schemaVersion"],
            "id": record["id"],
            "mode": record["mode"],
            "sha256": record["validationDigest"],
        }
        for record in records
    ]
    with open(manifest_path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    for old_name in ("puzzles-v1.json", "puzzles-v1-sample.json"):
        old_path = os.path.join(output_dir, old_name)
        if os.path.exists(old_path):
            os.remove(old_path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output-dir",
        default=os.path.join(os.path.dirname(os.path.dirname(__file__)), "content"),
    )
    args = parser.parse_args()
    records = generate_library()
    write_outputs(records, args.output_dir)

    from release_validator import validate_release

    validate_release(args.output_dir, exhaustive=True)
    print("release validation: PASS")


if __name__ == "__main__":
    main()
