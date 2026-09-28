# -*- coding: utf-8 -*-
"""Compact connected chain-layout generator for Kanji Nankuro boards."""
from __future__ import annotations

import random

from vocab2 import WORDS2, READING, MEANING


def build_graph(words2):
    graph = {}
    for item in words2:
        w = item[0] if isinstance(item, tuple) else item
        graph.setdefault(w[0], []).append((w, 0))
        graph.setdefault(w[1], []).append((w, 1))
    return graph


def runs_in_grid(occupied):
    if not occupied:
        return []
    rows = [r for r, _ in occupied]
    cols = [c for _, c in occupied]
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
    actual_sets = set(frozenset(cells) for cells in runs_in_grid(occupied))
    intended_sets = set(frozenset(cells) for cells in intended_slot_cellsets)
    return actual_sets == intended_sets


def _bbox_metrics(occupied):
    rows = [r for r, _ in occupied]
    cols = [c for _, c in occupied]
    height = max(rows) - min(rows) + 1
    width = max(cols) - min(cols) + 1
    area = height * width
    return area, max(height, width), height + width, height, width


def _cell_centrality(cell, occupied):
    rows = [r for r, _ in occupied]
    cols = [c for _, c in occupied]
    cr = (min(rows) + max(rows)) / 2.0
    cc = (min(cols) + max(cols)) / 2.0
    return abs(cell[0] - cr) + abs(cell[1] - cc)


def grow_chain_grid(
    start_word,
    graph,
    max_words=40,
    seed=0,
    candidate_cells=14,
    candidate_words=32,
):
    """Grow a deterministic compact board and fall back to a full scan."""
    rng = random.Random(seed)
    occupied = {(0, 0): start_word[0], (0, 1): start_word[1]}
    slots = [[(0, 0), (0, 1)]]
    used_words = {start_word}
    placed_records = [(start_word, [(0, 0), (0, 1)])]

    def dirs_for(cell):
        dirs = set()
        for slot in slots:
            if cell in slot and len(slot) > 1:
                dirs.add("H" if slot[0][0] == slot[1][0] else "V")
        return dirs

    def placement_options(cell, incoming_dir, word, junction_pos):
        r0, c0 = cell
        if occupied.get(cell) != word[junction_pos]:
            return []
        perp = "V" if incoming_dir == "H" else "H"
        options = []
        for sign in (1, -1):
            if perp == "V":
                cells = [
                    (r0 + sign * (i - junction_pos), c0)
                    for i in range(len(word))
                ]
            else:
                cells = [
                    (r0, c0 + sign * (i - junction_pos))
                    for i in range(len(word))
                ]
            if cells[junction_pos] != cell:
                continue
            if any(cc in occupied for i, cc in enumerate(cells) if i != junction_pos):
                continue
            trial = dict(occupied)
            for i, cc in enumerate(cells):
                trial[cc] = word[i]
            new_slots = slots + [cells]
            if not grid_is_consistent(trial, new_slots):
                continue
            area, max_dim, perimeter, height, width = _bbox_metrics(trial)
            aspect_penalty = abs(height - width)
            score = (area, max_dim, aspect_penalty, perimeter, rng.random())
            options.append((score, cells, trial))
        return options

    def candidate_placements(limited=True):
        cells = list(occupied.keys())
        cells.sort(key=lambda cell: (_cell_centrality(cell, occupied), rng.random()))
        if limited:
            cells = cells[:candidate_cells]
        for cell in cells:
            kanji = occupied[cell]
            dirs = dirs_for(cell)
            if not dirs:
                continue
            candidates = [
                pair for pair in graph.get(kanji, [])
                if pair[0] not in used_words
            ]
            rng.shuffle(candidates)
            if limited:
                candidates = candidates[:candidate_words]
            for word, jpos in candidates:
                options = []
                for direction in dirs:
                    options.extend(placement_options(cell, direction, word, jpos))
                if options:
                    score, new_cells, trial = min(options, key=lambda item: item[0])
                    return (score, word, new_cells, trial)
        return None

    while len(used_words) < max_words:
        best = candidate_placements(limited=True)
        if best is None:
            best = candidate_placements(limited=False)
        if best is None:
            break
        _, word, new_cells, trial = best
        occupied.clear()
        occupied.update(trial)
        slots.append(new_cells)
        used_words.add(word)
        placed_records.append((word, new_cells))

    if not grid_is_consistent(occupied, slots):
        raise AssertionError("final grid contains an unintended run")
    return occupied, slots, placed_records


if __name__ == "__main__":
    graph = build_graph(WORDS2)
    best = None
    for seed in range(40):
        start = WORDS2[seed % len(WORDS2)][0]
        occupied, slots, records = grow_chain_grid(
            start, graph, max_words=60, seed=seed
        )
        if best is None or len(records) > len(best[2]):
            best = (occupied, slots, records)
    occupied, slots, records = best
    area, _, _, height, width = _bbox_metrics(occupied)
    print(
        f"Largest connected grid found: {len(records)} words, "
        f"{len(occupied)} cells, {height}x{width}, density={len(occupied)/area:.3f}"
    )
    for w, _ in records[:15]:
        print(" ", w, READING.get(w, "?"), MEANING.get(w, ""))
