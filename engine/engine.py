# -*- coding: utf-8 -*-
"""
Minimal but REAL kanji-number-crossword (nankuro) generator + exhaustive
solver, used to answer one question honestly: given a small, hand-verified
vocabulary, how many puzzles with a mathematically guaranteed UNIQUE
solution can actually be produced?

Puzzle unit: a 2x2 "word square"
    a b
    c d
where "ab", "cd" (rows) and "ac", "bd" (columns) must all be entries in the
vocabulary. Cells are then replaced by NUMBERS (same kanji -> same number,
as in real nankuro), and a "starter" subset of numbers is revealed.

A puzzle is only accepted if, given the black/white skeleton + the revealed
starter numbers + the vocabulary as the solver's dictionary, EXACTLY ONE
assignment of kanji to numbers satisfies every row/column word constraint.
This mirrors the reliability invariant in the product spec: "every shipped
puzzle has exactly one accepted solution."
"""
from __future__ import annotations
from dataclasses import dataclass
from itertools import combinations
import hashlib
import json
import random

from vocab import WORDS as WORD_TUPLES, READING, MEANING

WORDS = [w for w, _, _ in WORD_TUPLES]
WORD_SET = set(WORDS)


def find_all_word_squares():
    """Brute-force every (a,b,c,d) such that ab, cd, ac, bd are all
    vocabulary words. This is the full candidate space, no shortcuts."""
    squares = []
    for ab in WORDS:
        a, b = ab[0], ab[1]
        for cd in WORDS:
            c, d = cd[0], cd[1]
            ac = a + c
            bd = b + d
            if ac in WORD_SET and bd in WORD_SET:
                squares.append((a, b, c, d))
    return squares


def numbering_for(square):
    """Group the 4 cells by identical kanji -> same number. Returns
    (cell_to_number dict in order a,b,c,d, number_to_kanji dict)."""
    a, b, c, d = square
    cells = ["a", "b", "c", "d"]
    values = [a, b, c, d]
    kanji_to_num = {}
    cell_to_num = {}
    next_num = 1
    for cell, v in zip(cells, values):
        if v not in kanji_to_num:
            kanji_to_num[v] = next_num
            next_num += 1
        cell_to_num[cell] = kanji_to_num[v]
    num_to_kanji = {n: k for k, n in kanji_to_num.items()}
    return cell_to_num, num_to_kanji


def count_solutions(cell_to_num: dict, starters: dict):
    """Exhaustively count how many (a,b,c,d) assignments satisfy the
    word-square constraints + starter reveals + number-identity
    constraints (same number forces same kanji, different numbers may
    still coincide unless we also require them distinct -- real nankuro
    numbers ARE 1:1 with kanji, so we also reject solutions where two
    different numbers land on the same kanji).

    Uses the FULL vocabulary as the solver's dictionary. Enumerates over
    dictionary words directly (not the raw kanji alphabet) so this stays
    fast: bounded by roughly |WORDS|^2, not |alphabet|^4.
    """
    num_a, num_b, num_c, num_d = (
        cell_to_num["a"], cell_to_num["b"], cell_to_num["c"], cell_to_num["d"],
    )
    solutions = []
    for ab in WORDS:
        a, b = ab[0], ab[1]
        if num_a in starters and starters[num_a] != a:
            continue
        if num_b in starters and starters[num_b] != b:
            continue
        for cd in WORDS:
            c, d = cd[0], cd[1]
            if num_c in starters and starters[num_c] != c:
                continue
            if num_d in starters and starters[num_d] != d:
                continue
            if (a + c) not in WORD_SET or (b + d) not in WORD_SET:
                continue
            # number-identity: equal numbers must be equal kanji, and
            # distinct numbers must map to distinct kanji (1 kanji <-> 1 number)
            values = {"a": a, "b": b, "c": c, "d": d}
            nums = {"a": num_a, "b": num_b, "c": num_c, "d": num_d}
            ok = True
            seen = {}
            for cell in "abcd":
                n = nums[cell]
                v = values[cell]
                if n in seen and seen[n] != v:
                    ok = False
                    break
                seen[n] = v
            if not ok:
                continue
            kanji_to_num = {}
            for cell in "abcd":
                v = values[cell]
                n = nums[cell]
                if v in kanji_to_num and kanji_to_num[v] != n:
                    ok = False
                    break
                kanji_to_num[v] = n
            if not ok:
                continue
            solutions.append((a, b, c, d))
    return solutions


def minimal_unique_starters(cell_to_num: dict, num_to_kanji: dict):
    """Find the smallest starter-reveal subset (by count) that forces a
    unique solution. Returns (starters_dict, solutions_count_at_full) or
    None if even revealing everything but one number is still ambiguous
    (shouldn't happen since revealing all numbers trivially is unique)."""
    numbers = sorted(set(cell_to_num.values()))
    for reveal_count in range(0, len(numbers) + 1):
        for subset in combinations(numbers, reveal_count):
            starters = {n: num_to_kanji[n] for n in subset}
            sols = count_solutions(cell_to_num, starters)
            if len(sols) == 1:
                return starters, len(numbers)
    return None


@dataclass
class Puzzle:
    square: tuple
    cell_to_num: dict
    num_to_kanji: dict
    starters: dict
    distinct_numbers: int

    def words(self):
        a, b, c, d = self.square
        return [a + b, c + d, a + c, b + d]

    def to_json(self, puzzle_id: str, difficulty: str):
        a, b, c, d = self.square
        layout = [["." , "."], [".", "."]]
        cell_numbers = {
            "0,0": self.cell_to_num["a"],
            "0,1": self.cell_to_num["b"],
            "1,0": self.cell_to_num["c"],
            "1,1": self.cell_to_num["d"],
        }
        solution = self.num_to_kanji
        words = self.words()
        tray = list(set(solution.values()))
        rnd = random.Random(puzzle_id)
        rnd.shuffle(tray)
        record = {
            "schemaVersion": 1,
            "id": puzzle_id,
            "mode": "kanjiNankuro",
            "difficulty": difficulty,
            "difficultyScore": len(self.starters) / max(1, self.distinct_numbers),
            "rows": 2,
            "columns": 2,
            "cellLayout": layout,
            "cellNumbers": cell_numbers,
            "solution": solution,
            "traySeed": tray,
            "starterCells": self.starters,
            "wordSpans": [
                {"word": words[0], "reading": READING[words[0]], "cells": ["0,0", "0,1"]},
                {"word": words[1], "reading": READING[words[1]], "cells": ["1,0", "1,1"]},
                {"word": words[2], "reading": READING[words[2]], "cells": ["0,0", "1,0"]},
                {"word": words[3], "reading": READING[words[3]], "cells": ["0,1", "1,1"]},
            ],
            "explanations": {w: MEANING[w] for w in words},
            "editorialStatus": "prototype_unreviewed",
            "sourceNotes": "Hand-curated common jukugo; needs native Japanese editorial sign-off before shipping.",
        }
        digest = hashlib.sha256(json.dumps(record, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()
        record["validationDigest"] = digest
        return record


def build_all_valid_puzzles():
    squares = find_all_word_squares()
    seen_signatures = set()
    puzzles = []
    for square in squares:
        cell_to_num, num_to_kanji = numbering_for(square)
        result = minimal_unique_starters(cell_to_num, num_to_kanji)
        if result is None:
            continue
        starters, distinct_numbers = result
        # Dedup: same multiset of 4 words regardless of square orientation
        sig = tuple(sorted(set([square[0]+square[1], square[2]+square[3], square[0]+square[2], square[1]+square[3]])))
        if sig in seen_signatures:
            continue
        seen_signatures.add(sig)
        puzzles.append(Puzzle(square, cell_to_num, num_to_kanji, starters, distinct_numbers))
    return puzzles


if __name__ == "__main__":
    squares = find_all_word_squares()
    print(f"Total word-square candidates found (rows/cols all valid words): {len(squares)}")
    puzzles = build_all_valid_puzzles()
    print(f"Distinct puzzles with a mathematically unique solution: {len(puzzles)}")

    solvable_with_le = {1: 0, 2: 0, 3: 0, 4: 0}
    for p in puzzles:
        solvable_with_le[len(p.starters)] += 1
    print("Breakdown by number of starter reveals needed for uniqueness:")
    for k, v in solvable_with_le.items():
        print(f"  needs {k} starter(s): {v} puzzles")

    # Split into "real" puzzles (4 genuinely distinct words -- an actual
    # variety of vocabulary in play) vs "degenerate" ones (the square is
    # symmetric, so only 2 distinct words appear, each doing double duty
    # as both a row and a column). Both are mathematically valid and
    # uniquely solvable, but only the first group is worth shipping as
    # real player-facing content; the degenerate ones are near-duplicates
    # of each other and of the real ones.
    real, degenerate = [], []
    for p in puzzles:
        n_distinct_words = len(set(p.words()))
        (real if n_distinct_words == 4 else degenerate).append(p)

    final = []
    for i, p in enumerate(real):
        difficulty = ["easy", "standard", "hard", "expert"][min(len(p.starters) - 1, 3)]
        final.append(p.to_json(f"nankuro-2x2-{i+1:03d}", difficulty))
    with open("puzzles_final.json", "w", encoding="utf-8") as f:
        json.dump(final, f, ensure_ascii=False, indent=2)

    print(f"\nShippable-quality puzzles (4 distinct words, unique solution): {len(real)}")
    print(f"Degenerate puzzles (only 2 distinct words, unique solution): {len(degenerate)}")
    print(f"Wrote {len(final)} finalized puzzle records to puzzles_final.json")
