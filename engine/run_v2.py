# -*- coding: utf-8 -*-
import json
import sys
import time
import hashlib

import grid as gridmod
from csp import Solver
from vocab2 import WORDS_BY_LEN, READING, MEANING


def numbering_for(cell_to_kanji, slot_cells_all):
    kanji_to_num = {}
    cell_to_num = {}
    next_num = 1
    # stable order: iterate cells in row-major order
    for cell in sorted(cell_to_kanji.keys()):
        v = cell_to_kanji[cell]
        if v not in kanji_to_num:
            kanji_to_num[v] = next_num
            next_num += 1
        cell_to_num[cell] = kanji_to_num[v]
    num_to_kanji = {n: k for k, n in kanji_to_num.items()}
    return cell_to_num, num_to_kanji


def word_for_slot(cells, cell_to_kanji):
    return "".join(cell_to_kanji[c] for c in cells)


def process_size(rows, cols, n_skeletons=6, max_candidates=300, verbose=True):
    skeletons = gridmod.find_valid_skeletons(rows, cols, n_wanted=n_skeletons, seed=7)
    total_real_puzzles = 0
    all_records = []
    for sidx, (black, across, down) in enumerate(skeletons):
        slots = across + down
        solver = Solver(slots, WORDS_BY_LEN)
        t0 = time.time()
        candidates = solver.fill_all(max_count=max_candidates)
        t1 = time.time()
        real = []
        for cand in candidates:
            words_used = [word_for_slot(cells, cand) for cells in slots]
            if len(set(words_used)) != len(words_used):
                continue  # shouldn't happen (forbid_repeat), safety check
            real.append(cand)
        if verbose:
            print(f"[{rows}x{cols} skeleton#{sidx}] slots={len(slots)} "
                  f"candidate fillings found={len(candidates)} (fill search {t1-t0:.1f}s)")

        # de-dup candidates by their multiset of words (different cell
        # orderings of the "same" content shouldn't double count)
        seen_sig = set()
        unique_candidates = []
        for cand in candidates:
            words_used = tuple(sorted(word_for_slot(cells, cand) for cells in slots))
            if words_used in seen_sig:
                continue
            seen_sig.add(words_used)
            unique_candidates.append(cand)

        n_checked = 0
        n_valid_unique = 0
        for cand in unique_candidates:
            cell_to_num, num_to_kanji = numbering_for(cand, slots)
            distinct_numbers = len(num_to_kanji)
            words_used = [word_for_slot(cells, cand) for cells in slots]
            distinct_words = len(set(words_used))
            starters = solver.greedy_starters(cell_to_num, num_to_kanji, attempts=8, seed=sidx * 1000 + n_checked)
            n_checked += 1
            if starters is None:
                continue
            n_valid_unique += 1
            all_records.append({
                "rows": rows, "cols": cols, "skeleton_idx": sidx,
                "black": black, "slots": slots,
                "cell_to_num": cell_to_num, "num_to_kanji": num_to_kanji,
                "starters": starters, "distinct_numbers": distinct_numbers,
                "distinct_words": distinct_words, "n_slots": len(slots),
                "words_used": words_used,
            })
        if verbose:
            print(f"    unique-word-content candidates={len(unique_candidates)} "
                  f"-> mathematically unique-solution puzzles={n_valid_unique}")
        total_real_puzzles += n_valid_unique
    return all_records


if __name__ == "__main__":
    sizes = [(4, 4), (5, 5)]
    if len(sys.argv) > 1:
        sizes = [tuple(int(x) for x in s.split("x")) for s in sys.argv[1:]]
    everything = []
    for (r, c) in sizes:
        recs = process_size(r, c)
        everything.extend(recs)
        full_quality = [r_ for r_ in recs if r_["distinct_words"] == r_["n_slots"]]
        print(f"=== {r}x{c} TOTAL: {len(recs)} unique-solution puzzles, "
              f"{len(full_quality)} with fully distinct vocabulary ===\n")
