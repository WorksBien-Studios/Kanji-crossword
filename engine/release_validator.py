# -*- coding: utf-8 -*-
"""Fail-closed release validator for the bundled puzzle library."""
from __future__ import annotations

import argparse
import json
import os
from collections import defaultdict

from csp import Solver
from content_exclude import EXCLUDE_WORDS
from difficulty import compute_difficulty
from schema_v2 import (
    ALLOWED_DIFFICULTIES,
    ALLOWED_MODES,
    SCHEMA_VERSION,
    assign_difficulty_bands,
    content_id,
    mode_for_word_count,
    validation_digest,
)
from vocab3 import READING, WORDS_BY_LEN

REQUIRED_FIELDS = {
    "schemaVersion",
    "id",
    "mode",
    "difficulty",
    "difficultyScore",
    "difficultyMetrics",
    "rows",
    "columns",
    "cellLayout",
    "cellNumbers",
    "solution",
    "traySeed",
    "starterCells",
    "wordSpans",
    "editorialStatus",
    "editorialNotes",
    "sourceNotes",
    "validationDigest",
}


def _cell(text):
    parts = text.split(",")
    if len(parts) != 2:
        raise ValueError(f"invalid cell coordinate {text!r}")
    return int(parts[0]), int(parts[1])


def _restricted_words(record):
    tray = set(record["traySeed"])
    return [word for word in WORDS_BY_LEN[2] if set(word) <= tray]


def _structure_for_solver(record):
    cell_to_num = {_cell(key): value for key, value in record["cellNumbers"].items()}
    slots = [[_cell(key) for key in span["cells"]] for span in record["wordSpans"]]
    starters = {int(num): value for num, value in record["starterCells"].items()}
    return slots, cell_to_num, starters


def _validate_record(record, global_words, exhaustive):
    errors = []
    rid = record.get("id", "<missing-id>")
    fields = set(record)
    if fields != REQUIRED_FIELDS:
        missing = sorted(REQUIRED_FIELDS - fields)
        unknown = sorted(fields - REQUIRED_FIELDS)
        errors.append(f"{rid}: schema fields missing={missing} unknown={unknown}")
        return errors

    if record["schemaVersion"] != SCHEMA_VERSION:
        errors.append(f"{rid}: unsupported schemaVersion {record['schemaVersion']}")
    if record["mode"] not in ALLOWED_MODES:
        errors.append(f"{rid}: invalid mode {record['mode']!r}")
    if record["difficulty"] not in ALLOWED_DIFFICULTIES:
        errors.append(f"{rid}: invalid difficulty {record['difficulty']!r}")

    rows, columns = record["rows"], record["columns"]
    if not isinstance(rows, int) or rows <= 0 or not isinstance(columns, int) or columns <= 0:
        errors.append(f"{rid}: invalid dimensions {rows}x{columns}")
        return errors
    layout = record["cellLayout"]
    if len(layout) != rows or any(len(row) != columns for row in layout):
        errors.append(f"{rid}: layout dimensions do not match rows/columns")
        return errors
    if any(value not in {"#", "."} for row in layout for value in row):
        errors.append(f"{rid}: layout contains an unknown token")

    play_cells = {
        f"{r},{c}"
        for r, row in enumerate(layout)
        for c, value in enumerate(row)
        if value == "."
    }
    numbered_cells = set(record["cellNumbers"])
    if play_cells != numbered_cells:
        errors.append(f"{rid}: playable cells and cellNumbers differ")

    solution = {int(num): value for num, value in record["solution"].items()}
    numbers = set(record["cellNumbers"].values())
    if numbers != set(solution):
        errors.append(f"{rid}: solution keys do not match cell numbers")
    if len(set(solution.values())) != len(solution):
        errors.append(f"{rid}: number-to-kanji mapping is not one-to-one")
    if any(len(value) != 1 for value in solution.values()):
        errors.append(f"{rid}: a solution value is not one kanji code point")

    tray = record["traySeed"]
    if len(tray) != len(set(tray)) or set(tray) != set(solution.values()):
        errors.append(f"{rid}: tray is not an exact permutation of solution kanji")

    starters = {int(num): value for num, value in record["starterCells"].items()}
    for num, value in starters.items():
        if solution.get(num) != value:
            errors.append(f"{rid}: starter {num} does not match solution")

    covered = set()
    local_words = set()
    adjacency = defaultdict(set)
    for span in record["wordSpans"]:
        word = span.get("word")
        reading = span.get("reading")
        cells = span.get("cells")
        if not isinstance(word, str) or not isinstance(reading, str) or not isinstance(cells, list):
            errors.append(f"{rid}: malformed word span")
            continue
        if len(word) != len(cells):
            errors.append(f"{rid}: word/cell length mismatch for {word!r}")
            continue
        if word in local_words:
            errors.append(f"{rid}: duplicate word inside puzzle: {word}")
        local_words.add(word)
        if word in global_words:
            errors.append(f"{rid}: word reused across puzzles: {word}")
        global_words.add(word)
        if word in EXCLUDE_WORDS:
            errors.append(f"{rid}: prohibited word shipped: {word}")
        if READING.get(word) != reading:
            errors.append(f"{rid}: missing/stale reading for {word}: {reading!r}")
        coords = []
        for index, cell_text in enumerate(cells):
            if cell_text not in numbered_cells:
                errors.append(f"{rid}: {word} references non-play cell {cell_text}")
                continue
            covered.add(cell_text)
            coord = _cell(cell_text)
            coords.append(coord)
            num = record["cellNumbers"][cell_text]
            if solution.get(num) != word[index]:
                errors.append(f"{rid}: {word} disagrees with solution at {cell_text}")
        if len(coords) == len(cells) and len(coords) > 1:
            same_row = all(r == coords[0][0] for r, _ in coords)
            same_col = all(c == coords[0][1] for _, c in coords)
            if not same_row and not same_col:
                errors.append(f"{rid}: {word} is not straight")
            for left, right, left_text, right_text in zip(
                coords, coords[1:], cells, cells[1:]
            ):
                if abs(left[0] - right[0]) + abs(left[1] - right[1]) != 1:
                    errors.append(f"{rid}: {word} is not contiguous")
                adjacency[left_text].add(right_text)
                adjacency[right_text].add(left_text)

    if covered != play_cells:
        errors.append(f"{rid}: not every play cell belongs to a word span")
    if play_cells:
        first = next(iter(play_cells))
        seen = {first}
        stack = [first]
        while stack:
            cur = stack.pop()
            for nxt in adjacency[cur]:
                if nxt not in seen:
                    seen.add(nxt)
                    stack.append(nxt)
        if seen != play_cells:
            errors.append(f"{rid}: play grid is disconnected")

    expected_mode = mode_for_word_count(len(record["wordSpans"]))
    if record["mode"] != expected_mode:
        errors.append(f"{rid}: mode {record['mode']} should be {expected_mode}")

    if content_id(record) != rid:
        errors.append(f"{rid}: content-addressed id does not match gameplay payload")
    if validation_digest(record) != record["validationDigest"]:
        errors.append(f"{rid}: validationDigest mismatch")

    restricted = _restricted_words(record)
    slots, cell_to_num, solver_starters = _structure_for_solver(record)
    records_for_metrics = [
        (span["word"], [_cell(cell) for cell in span["cells"]])
        for span in record["wordSpans"]
    ]
    expected_score, expected_metrics = compute_difficulty(
        records_for_metrics, cell_to_num, solver_starters, restricted
    )
    if expected_score != record["difficultyScore"]:
        errors.append(
            f"{rid}: difficultyScore {record['difficultyScore']} != {expected_score}"
        )
    if expected_metrics != record["difficultyMetrics"]:
        errors.append(f"{rid}: difficultyMetrics are stale")

    if exhaustive:
        solver = Solver(slots, {2: restricted})
        solutions = solver.count_with_numbering(
            cell_to_num, solver_starters, cap=2, forbid_repeat=False
        )
        if len(solutions) != 1:
            errors.append(f"{rid}: expected exactly one solution, found {len(solutions)}")
        else:
            solved = solutions[0]
            for cell, number in cell_to_num.items():
                if solved.get(cell) != solution[number]:
                    errors.append(f"{rid}: exhaustive solver returned wrong mapping")
                    break
    return errors


def validate_release(content_dir, exhaustive=True):
    puzzle_path = os.path.join(content_dir, "puzzles-v2.json")
    manifest_path = os.path.join(content_dir, "manifest.json")
    with open(puzzle_path, encoding="utf-8") as handle:
        puzzles = json.load(handle)
    with open(manifest_path, encoding="utf-8") as handle:
        manifest = json.load(handle)

    errors = []
    if len(puzzles) != 360:
        errors.append(f"library must contain 360 puzzles; found {len(puzzles)}")
    ids = [record.get("id") for record in puzzles]
    if len(ids) != len(set(ids)):
        errors.append("duplicate puzzle ids")

    global_words = set()
    for record in puzzles:
        errors.extend(_validate_record(record, global_words, exhaustive))

    copies = [dict(record) for record in puzzles]
    assign_difficulty_bands(copies)
    expected_bands = {record["id"]: record["difficulty"] for record in copies}
    for record in puzzles:
        if expected_bands.get(record["id"]) != record["difficulty"]:
            errors.append(f"{record['id']}: difficulty band is stale")

    manifest_by_id = {entry.get("id"): entry for entry in manifest}
    if len(manifest) != len(puzzles) or len(manifest_by_id) != len(manifest):
        errors.append("manifest count/uniqueness does not match puzzle library")
    for record in puzzles:
        entry = manifest_by_id.get(record["id"])
        if entry is None:
            errors.append(f"{record['id']}: missing manifest entry")
            continue
        expected = {
            "schemaVersion": record["schemaVersion"],
            "id": record["id"],
            "mode": record["mode"],
            "sha256": record["validationDigest"],
        }
        if entry != expected:
            errors.append(f"{record['id']}: manifest entry mismatch")

    if errors:
        sample = "\n".join(f"- {error}" for error in errors[:100])
        raise AssertionError(f"release validation failed ({len(errors)} errors):\n{sample}")
    return {"puzzles": len(puzzles), "words": len(global_words)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "content_dir",
        nargs="?",
        default=os.path.join(os.path.dirname(os.path.dirname(__file__)), "content"),
    )
    parser.add_argument("--structural-only", action="store_true")
    args = parser.parse_args()
    summary = validate_release(args.content_dir, exhaustive=not args.structural_only)
    print(f"PASS: {summary['puzzles']} puzzles, {summary['words']} unique words")


if __name__ == "__main__":
    main()
