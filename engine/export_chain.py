# -*- coding: utf-8 -*-
import json
import hashlib
import random

from chain_layout import build_graph, grow_chain_grid
from vocab2 import WORDS2, WORDS_BY_LEN, READING, MEANING
from csp import Solver


def to_record(occupied, slots, records, cell_to_num, num_to_kanji, starters, puzzle_id, difficulty):
    rows = [r for r, c in occupied]
    cols = [c for r, c in occupied]
    rmin, rmax = min(rows), max(rows)
    cmin, cmax = min(cols), max(cols)
    nrows, ncols = rmax - rmin + 1, cmax - cmin + 1
    layout = [["#"] * ncols for _ in range(nrows)]
    cell_numbers = {}
    for (r, c), num in cell_to_num.items():
        rr, cc = r - rmin, c - cmin
        layout[rr][cc] = "."
        cell_numbers[f"{rr},{cc}"] = num
    starters_shifted = dict(starters)
    word_spans = []
    for w, cells in records:
        shifted = [f"{r-rmin},{c-cmin}" for r, c in cells]
        word_spans.append({"word": w, "reading": READING[w], "cells": shifted})
    tray = list(num_to_kanji.values())
    rnd = random.Random(puzzle_id)
    rnd.shuffle(tray)
    record = {
        "schemaVersion": 1,
        "id": puzzle_id,
        "mode": "kanjiNankuroLarge",
        "difficulty": difficulty,
        "difficultyScore": round(len(starters) / max(1, len(num_to_kanji)), 3),
        "rows": nrows,
        "columns": ncols,
        "cellLayout": layout,
        "cellNumbers": cell_numbers,
        "solution": num_to_kanji,
        "traySeed": tray,
        "starterCells": starters,
        "wordSpans": word_spans,
        "explanations": {w: MEANING[w] for w, _ in records},
        "editorialStatus": "prototype_unreviewed",
        "sourceNotes": "Hand-curated common jukugo, chain-linked layout; needs native Japanese editorial sign-off before shipping.",
    }
    digest = hashlib.sha256(json.dumps(record, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()
    record["validationDigest"] = digest
    return record


def main():
    graph = build_graph(WORDS2)
    seen_sigs = set()
    candidates = []
    for seed in range(60):
        start = WORDS2[seed % len(WORDS2)][0]
        occupied, slots, records = grow_chain_grid(start, graph, max_words=60, seed=seed)
        if len(records) < 15:
            continue
        words_used = frozenset(w for w, _ in records)
        if words_used in seen_sigs:
            continue
        seen_sigs.add(words_used)
        candidates.append((occupied, slots, records))

    # pick a size-diverse sample: smallest, a couple mid-size, largest
    candidates.sort(key=lambda t: len(t[2]))
    sample_idxs = sorted(set([0, len(candidates)//3, 2*len(candidates)//3, len(candidates)-1]))
    out = []
    for i, idx in enumerate(sample_idxs):
        occupied, slots, records = candidates[idx]
        kanji_to_num = {}
        cell_to_num = {}
        for cell in sorted(occupied.keys()):
            v = occupied[cell]
            if v not in kanji_to_num:
                kanji_to_num[v] = len(kanji_to_num) + 1
            cell_to_num[cell] = kanji_to_num[v]
        num_to_kanji = {n: k for k, n in kanji_to_num.items()}
        solver = Solver(slots, WORDS_BY_LEN)
        starters = solver.greedy_starters(cell_to_num, num_to_kanji, attempts=6, seed=99, cap_check=2)
        assert starters is not None
        sols = solver.count_with_numbering(cell_to_num, starters, cap=2)
        assert len(sols) == 1, "uniqueness check failed at export time"
        n_words = len(records)
        difficulty = "easy" if n_words < 22 else "standard" if n_words < 32 else "hard" if n_words < 45 else "expert"
        rec = to_record(occupied, slots, records, cell_to_num, num_to_kanji, starters,
                         f"nankuro-large-{i+1:03d}", difficulty)
        out.append(rec)
        print(f"exported {rec['id']}: {n_words} words, {rec['rows']}x{rec['columns']} board, "
              f"{len(starters)}/{len(num_to_kanji)} starters, difficulty={difficulty}")

    with open("puzzles_large.json", "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"wrote {len(out)} large puzzle records to puzzles_large.json")


if __name__ == "__main__":
    main()
