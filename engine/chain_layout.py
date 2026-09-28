# -*- coding: utf-8 -*-
"""
Build ONE large, genuinely connected nankuro grid by chaining words
together at shared single kanji (branching tree layout), instead of a
dense double-checked crossword. This matches how real nankuro grids
mostly work (most cells are single-checked; true 4-way crossings are the
exception, not the rule) and needs far less vocabulary density than a
tight word-square-style grid to become fillable.

After every placement we recompute the ACTUAL across/down runs of the
grid built so far and require them to exactly match the intended word
list -- this catches any accidental adjacency/merge bug immediately
rather than trusting the placement logic blindly.
"""
from __future__ import annotations
import random
from vocab2 import WORDS2, READING, MEANING


def build_graph(words2):
    """kanji -> list of (word, junction_position). A word can attach to an
    existing cell either via its first character OR its second -- using
    only the first (as before) throws away roughly half of every word's
    connective value."""
    graph = {}
    for w, _, _ in words2:
        graph.setdefault(w[0], []).append((w, 0))
        graph.setdefault(w[1], []).append((w, 1))
    return graph


def runs_in_grid(occupied):
    """occupied: dict (r,c)->char. Returns list of cell-lists for every
    maximal run (across then down) of length >= 2."""
    if not occupied:
        return []
    rows = [r for r, c in occupied]
    cols = [c for r, c in occupied]
    rmin, rmax = min(rows), max(rows)
    cmin, cmax = min(cols), max(cols)
    runs = []
    for r in range(rmin, rmax + 1):
        run = []
        for c in range(cmin, cmax + 2):
            if (r, c) in occupied:
                run.append((r, c))
            else:
                if len(run) >= 2:
                    runs.append(list(run))
                run = []
    for c in range(cmin, cmax + 1):
        run = []
        for r in range(rmin, rmax + 2):
            if (r, c) in occupied:
                run.append((r, c))
            else:
                if len(run) >= 2:
                    runs.append(list(run))
                run = []
    return runs


def grid_is_consistent(occupied, intended_slot_cellsets):
    actual = [tuple(cells) for cells in runs_in_grid(occupied)]
    actual_sets = set(frozenset(cells) for cells in actual)
    intended_sets = set(frozenset(cells) for cells in intended_slot_cellsets)
    return actual_sets == intended_sets


def grow_chain_grid(start_word, graph, max_words=40, seed=0):
    rng = random.Random(seed)
    a, b = start_word[0], start_word[1]
    occupied = {(0, 0): a, (0, 1): b}
    slots = [[(0, 0), (0, 1)]]
    used_words = {start_word}
    # frontier: list of (cell, direction_of_word_through_it) direction: 'H' or 'V'
    frontier = [((0, 0), "H"), ((0, 1), "H")]

    def try_place(cell, incoming_dir, word, junction_pos):
        r0, c0 = cell
        kanji = word[junction_pos]
        assert occupied.get(cell) == kanji
        perp = "V" if incoming_dir == "H" else "H"
        length = len(word)
        for sign in (1, -1):
            if perp == "V":
                cells = [(r0 + sign * (i - junction_pos), c0) for i in range(length)]
            else:
                cells = [(r0, c0 + sign * (i - junction_pos)) for i in range(length)]
            if cells[junction_pos] != cell:
                continue
            ok = True
            for i, cc in enumerate(cells):
                if i == junction_pos:
                    continue
                if cc in occupied:
                    ok = False
                    break
            if not ok:
                continue
            trial = dict(occupied)
            for i, cc in enumerate(cells):
                trial[cc] = word[i]
            new_slots = slots + [cells]
            if grid_is_consistent(trial, new_slots):
                return cells, trial
        return None, None

    frontier_order = list(frontier)
    rng.shuffle(frontier_order)
    idx = 0
    placed_records = [(start_word, [(0, 0), (0, 1)])]
    attempts_exhausted = set()

    while len(used_words) < max_words:
        progressed = False
        cells_to_try = list(occupied.keys())
        rng.shuffle(cells_to_try)
        for cell in cells_to_try:
            kanji = occupied[cell]
            # figure out this cell's existing direction(s) by checking slots
            dirs_here = set()
            for s in slots:
                if cell in s:
                    if len(s) > 1:
                        dirs_here.add("H" if s[0][0] == s[1][0] else "V")
            if not dirs_here:
                continue
            candidates = [(w, jpos) for (w, jpos) in graph.get(kanji, []) if w not in used_words]
            rng.shuffle(candidates)
            placed_here = False
            for w, jpos in candidates:
                for d in dirs_here:
                    cells, trial = try_place(cell, d, w, jpos)
                    if cells is not None:
                        occupied.clear()
                        occupied.update(trial)
                        slots.append(cells)
                        used_words.add(w)
                        placed_records.append((w, cells))
                        placed_here = True
                        break
                if placed_here:
                    break
            if placed_here:
                progressed = True
                break
        if not progressed:
            break
    return occupied, slots, placed_records


if __name__ == "__main__":
    graph = build_graph(WORDS2)
    best = None
    for seed in range(40):
        start = WORDS2[seed % len(WORDS2)][0]
        occupied, slots, records = grow_chain_grid(start, graph, max_words=60, seed=seed)
        if best is None or len(records) > len(best[2]):
            best = (occupied, slots, records)
    occupied, slots, records = best
    print(f"Largest single connected chain grid found: {len(records)} words, "
          f"{len(occupied)} cells, bounding box "
          f"{max(r for r,c in occupied)-min(r for r,c in occupied)+1} x "
          f"{max(c for r,c in occupied)-min(c for r,c in occupied)+1}")
    for w, cells in records[:15]:
        print(" ", w, READING.get(w, "?"))
    if len(records) > 15:
        print(f"  ... and {len(records)-15} more")
