# -*- coding: utf-8 -*-
import json
import time
import random
import hashlib

from partition import partition_all
from vocab3 import WORDS2, WORDS_BY_LEN, READING, DICTIONARY_ATTRIBUTION
from csp import Solver
from fast_tree import build_pos_index2, fast_starters_for_chain


def numbering_for(occupied):
    kanji_to_num = {}
    cell_to_num = {}
    for cell in sorted(occupied.keys()):
        v = occupied[cell]
        if v not in kanji_to_num:
            kanji_to_num[v] = len(kanji_to_num) + 1
        cell_to_num[cell] = kanji_to_num[v]
    return cell_to_num, {n: k for k, n in kanji_to_num.items()}


def to_record(occupied, records, cell_to_num, num_to_kanji, starters, puzzle_id, difficulty):
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
    word_spans = []
    for w, cells in records:
        shifted = [f"{r - rmin},{c - cmin}" for r, c in cells]
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
        "explanations": {},  # still pending: per-word Japanese explanations have not been authored
        "editorialStatus": "localisation_review_passed",
        "editorialNotes": (
            "Localisation review performed by AI (Claude), not a native-speaker "
            "linguist -- no native reviewer was available for this project. "
            "Review basis: automated JMdict common-word/POS/misc filtering, a fix "
            "for an entry-grouping bug that mismatched some readings, an "
            "exhaustive manual pass over every word containing a risk-associated "
            "kanji (violence/weapons/death/crime/exploitation), an exhaustive "
            "check against known defunct Japanese government ministry names, and "
            "broad (~8%, not exhaustive) random sampling for reading correctness "
            "and natural phrasing. Passed and approved by project owner 2026-09-28."
        ),
        "sourceNotes": DICTIONARY_ATTRIBUTION,
    }
    digest = hashlib.sha256(json.dumps(record, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()
    record["validationDigest"] = digest
    return record


def main():
    t0 = time.time()
    puzzles, remaining = partition_all(WORDS2, min_words=12, max_words=45, seed=42,
                                        max_puzzles=3000, max_consecutive_stalls=8000)
    print(f"partition: {len(puzzles)} puzzles, {time.time()-t0:.1f}s")

    t0 = time.time()
    all_final = []
    verify_sample_solver_checks = 0
    fails = 0
    for i, (occupied, slots, records) in enumerate(puzzles):
        cell_to_num, num_to_kanji = numbering_for(occupied)
        # REAL nankuro mechanic: the player is given a tray with exactly the
        # kanji in play (shuffled). Solving means deducing the assignment
        # among THOSE kanji, not searching the whole language dictionary.
        # So the solver's dictionary must be restricted to words composed
        # only of this puzzle's own tray kanji.
        tray = set(occupied.values())
        restricted2 = [w for w in WORDS_BY_LEN[2] if set(w) <= tray]
        by_pos2_local = build_pos_index2(restricted2)
        starters, forced, ambiguous = fast_starters_for_chain(records, occupied, cell_to_num, by_pos2_local)
        n_words = len(records)
        difficulty = ("easy" if n_words < 18 else "standard" if n_words < 26
                      else "hard" if n_words < 35 else "expert")
        rec = to_record(occupied, records, cell_to_num, num_to_kanji, starters,
                         f"nankuro-jmdict-{i+1:04d}", difficulty)
        all_final.append((rec, slots, cell_to_num, restricted2))

        if i < 25:  # spot-check a sample with the slow, trusted exhaustive verifier
            solver = Solver(slots, {2: restricted2})
            sols = solver.count_with_numbering(cell_to_num, starters, cap=2)
            verify_sample_solver_checks += 1
            if len(sols) != 1:
                fails += 1
                print(f"  ** VERIFICATION FAILURE ** puzzle {i} not unique: {len(sols)} solutions found")

    print(f"starter computation + spot verification: {time.time()-t0:.1f}s")
    print(f"spot-verified {verify_sample_solver_checks} puzzles with the slow exhaustive solver, "
          f"failures={fails}")

    sizes = [len(r) for _, _, r in puzzles]
    starter_ratios = [rec["difficultyScore"] for rec, _, _, _ in all_final]
    print(f"TOTAL PUZZLES: {len(all_final)}")
    print(f"word count distribution: min={min(sizes)} max={max(sizes)} avg={sum(sizes)/len(sizes):.1f}")
    print(f"starter/number ratio distribution: min={min(starter_ratios):.2f} "
          f"max={max(starter_ratios):.2f} avg={sum(starter_ratios)/len(starter_ratios):.2f}")

    import collections
    diff_counts = collections.Counter(rec["difficulty"] for rec, _, _, _ in all_final)
    print("difficulty breakdown:", dict(diff_counts))

    # export the full library (metadata JSON, no huge explanations) + a small
    # full-detail sample
    out_full = [rec for rec, _, _, _ in all_final]
    with open("puzzles_jmdict_full_library.json", "w", encoding="utf-8") as f:
        json.dump(out_full, f, ensure_ascii=False, indent=1)

    sample_idxs = sorted(set([0, len(out_full)//4, len(out_full)//2, 3*len(out_full)//4, len(out_full)-1]))
    sample = [out_full[i] for i in sample_idxs]
    with open("puzzles_jmdict_sample.json", "w", encoding="utf-8") as f:
        json.dump(sample, f, ensure_ascii=False, indent=2)
    print(f"wrote {len(out_full)} records to puzzles_jmdict_full_library.json "
          f"and a {len(sample)}-puzzle sample to puzzles_jmdict_sample.json")


if __name__ == "__main__":
    main()
