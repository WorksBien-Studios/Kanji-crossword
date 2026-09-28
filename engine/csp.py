# -*- coding: utf-8 -*-
"""
Generic crossword-slot CSP: fills a skeleton's slots from a dictionary,
and (separately) proves whether a given numbering + starter reveal has a
UNIQUE solution against the full dictionary. This generalizes engine.py's
2x2 word-square logic to any grid size / slot mix.
"""
from __future__ import annotations
import random


class Solver:
    def __init__(self, slots, words_by_len):
        # slots: list of list[(r,c)]
        self.slots = slots
        self.words_by_len = words_by_len
        # cell -> list of (slot_idx, position_in_slot)
        self.cell_to_slots = {}
        for si, cells in enumerate(slots):
            for pos, cell in enumerate(cells):
                self.cell_to_slots.setdefault(cell, []).append((si, pos))
        # position index for fast candidate lookup at scale (10k+ words):
        # pos_index[length][position][char] -> set of words
        self.pos_index = {}
        for length, words in words_by_len.items():
            by_pos = [dict() for _ in range(length)]
            for w in words:
                for i, ch in enumerate(w):
                    by_pos[i].setdefault(ch, set()).add(w)
            self.pos_index[length] = by_pos

    def candidates(self, slot_idx, grid_state):
        cells = self.slots[slot_idx]
        length = len(cells)
        by_pos = self.pos_index.get(length)
        if by_pos is None:
            return []
        known = [(i, grid_state.get(cell)) for i, cell in enumerate(cells) if grid_state.get(cell) is not None]
        if not known:
            return list(self.words_by_len.get(length, []))
        sets = []
        for i, v in known:
            s = by_pos[i].get(v)
            if not s:
                return []
            sets.append(s)
        sets.sort(key=len)
        result = set(sets[0])
        for s in sets[1:]:
            result &= s
            if not result:
                return []
        return list(result)

    def fill_all(self, max_count=2000, forbid_repeat=True, rng=None):
        """Enumerate up to max_count full grid fillings (dict cell->kanji),
        each using every slot's word exactly once as a dictionary entry,
        no repeated words within one grid."""
        n = len(self.slots)
        order = list(range(n))
        results = []

        def backtrack(grid_state, used_words):
            if len(results) >= max_count:
                return
            # pick unfilled slot with fewest candidates (MRV)
            best = None
            best_cands = None
            for si in order:
                cells = self.slots[si]
                if all(grid_state.get(c) is not None for c in cells):
                    continue
                cands = self.candidates(si, grid_state)
                if forbid_repeat:
                    cands = [w for w in cands if w not in used_words]
                if best is None or len(cands) < len(best_cands):
                    best, best_cands = si, cands
                    if len(cands) <= 1:
                        break
            if best is None:
                results.append(dict(grid_state))
                return
            if not best_cands:
                return
            cells = self.slots[best]
            cands = list(best_cands)
            if rng:
                rng.shuffle(cands)
            for w in cands:
                new_state = dict(grid_state)
                for i, cell in enumerate(cells):
                    new_state[cell] = w[i]
                used_words.add(w)
                backtrack(new_state, used_words)
                used_words.discard(w)
                if len(results) >= max_count:
                    return

        backtrack({}, set())
        return results

    def count_with_numbering(self, cell_to_number, starters, cap=2, forbid_repeat=True):
        """Count solutions (up to `cap`) consistent with the numbering
        scheme (same number => same kanji, distinct numbers => distinct
        kanji) and the starter reveals, searching the FULL dictionary."""
        n = len(self.slots)
        solutions = []

        def try_solve(grid_state, num_to_kanji, kanji_to_num, used_words):
            if len(solutions) >= cap:
                return
            best = None
            best_cands = None
            for si in range(n):
                cells = self.slots[si]
                if all(grid_state.get(c) is not None for c in cells):
                    continue
                cands = self.candidates(si, grid_state)
                if forbid_repeat:
                    cands = [w for w in cands if w not in used_words]
                if best is None or len(cands) < len(best_cands):
                    best, best_cands = si, cands
                    if len(cands) <= 1:
                        break
            if best is None:
                solutions.append(dict(grid_state))
                return
            if not best_cands:
                return
            cells = self.slots[best]
            for w in best_cands:
                ok = True
                touched_nums = []
                touched_kanji = []
                for i, cell in enumerate(cells):
                    if grid_state.get(cell) is not None:
                        continue
                    num = cell_to_number[cell]
                    val = w[i]
                    if num in num_to_kanji:
                        if num_to_kanji[num] != val:
                            ok = False
                            break
                        continue
                    if val in kanji_to_num:
                        ok = False
                        break
                    num_to_kanji[num] = val
                    kanji_to_num[val] = num
                    touched_nums.append(num)
                    touched_kanji.append(val)
                if ok:
                    new_state = dict(grid_state)
                    for i, cell in enumerate(cells):
                        new_state[cell] = w[i]
                    used_words.add(w)
                    try_solve(new_state, num_to_kanji, kanji_to_num, used_words)
                    used_words.discard(w)
                for num in touched_nums:
                    del num_to_kanji[num]
                for val in touched_kanji:
                    del kanji_to_num[val]
                if len(solutions) >= cap:
                    return

        num_to_kanji = dict(starters)
        kanji_to_num = {}
        for n_, v in starters.items():
            if v in kanji_to_num and kanji_to_num[v] != n_:
                return []  # contradictory starters (shouldn't happen)
            kanji_to_num[v] = n_
        try_solve({}, num_to_kanji, kanji_to_num, set())
        return solutions

    def greedy_starters(self, cell_to_number, true_numbering_kanji, attempts=12, seed=0, cap_check=2):
        """Find a small (not guaranteed minimal) starter set that makes
        the puzzle uniquely solvable, by revealing numbers from the true
        solution one at a time until count_with_numbering returns 1."""
        numbers = sorted(set(cell_to_number.values()))
        rng = random.Random(seed)
        best = None
        for attempt in range(attempts):
            order = list(numbers)
            rng.shuffle(order)
            starters = {}
            for num in order:
                sols = self.count_with_numbering(cell_to_number, starters, cap=cap_check)
                if len(sols) == 1:
                    break
                starters[num] = true_numbering_kanji[num]
            else:
                sols = self.count_with_numbering(cell_to_number, starters, cap=cap_check)
            if len(sols) != 1:
                continue
            if best is None or len(starters) < len(best):
                best = dict(starters)
            if best is not None and len(best) <= 1:
                break
        return best
