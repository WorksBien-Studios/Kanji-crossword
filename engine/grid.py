# -*- coding: utf-8 -*-
"""
Grid skeleton generation + validation for the nankuro prototype.

A skeleton is an R x C boolean grid (True = black/blocked). We require:
  - 180-degree rotational symmetry (standard crossword convention).
  - Every maximal white run (across or down) has length 0, 2 or 3 --
    matching our word lengths. No length-1 dangling cells, no runs >= 4
    (we have no words that long yet).
  - Every white cell belongs to at least one run of length >= 2 (so no
    cell is totally unconstrained / meaningless).
"""
from __future__ import annotations
import random


def runs_in_line(line):
    """line: list of bool (True=black). Returns list of (start, length)
    for maximal white runs."""
    runs = []
    start = None
    for i, blocked in enumerate(line + [True]):
        if not blocked and start is None:
            start = i
        elif blocked and start is not None:
            runs.append((start, i - start))
            start = None
    return runs


def validate_skeleton(black, rows, cols):
    # check every row/col run length in {0,2,3}
    covered = [[False] * cols for _ in range(rows)]
    across_slots = []
    down_slots = []
    for r in range(rows):
        line = [black[r][c] for c in range(cols)]
        for start, length in runs_in_line(line):
            if length == 1:
                return None
            if length >= 4:
                return None
            if length >= 2:
                cells = [(r, start + i) for i in range(length)]
                across_slots.append(cells)
                for (rr, cc) in cells:
                    covered[rr][cc] = True
    for c in range(cols):
        line = [black[r][c] for r in range(rows)]
        for start, length in runs_in_line(line):
            if length == 1:
                return None
            if length >= 4:
                return None
            if length >= 2:
                cells = [(start + i, c) for i in range(length)]
                down_slots.append(cells)
                for (rr, cc) in cells:
                    covered[rr][cc] = True
    for r in range(rows):
        for c in range(cols):
            if not black[r][c] and not covered[r][c]:
                return None  # isolated white cell in no word at all
    return across_slots, down_slots


def _symmetric_pair_groups(rows, cols):
    groups = []
    seen = set()
    for r in range(rows):
        for c in range(cols):
            r2, c2 = rows - 1 - r, cols - 1 - c
            key = frozenset([(r, c), (r2, c2)])
            if key not in seen:
                seen.add(key)
                groups.append(list(key))
    return groups


def _apply_bits(bits, groups, rows, cols):
    black = [[False] * cols for _ in range(rows)]
    for b, grp in zip(bits, groups):
        if b:
            for (r, c) in grp:
                black[r][c] = True
    return black


def find_valid_skeletons(rows, cols, n_wanted=5, black_fraction=0.24, seed=0, tries=200000,
                          require_interlocked=False):
    """Exhaustive search for small grids (<=6x6), random sampling with
    180-degree symmetry for larger ones."""
    groups = _symmetric_pair_groups(rows, cols)
    found = []

    def accept(across_slots, down_slots):
        if len(across_slots) + len(down_slots) < 4:
            return False
        if require_interlocked and not is_interlocked(across_slots, down_slots):
            return False
        return True

    if rows * cols <= 36:
        import itertools
        target_black = int(round(rows * cols * black_fraction))
        combos = list(itertools.product([0, 1], repeat=len(groups)))
        def black_count(bits):
            return sum(2 if len(grp) == 2 else 1 for b, grp in zip(bits, groups) if b)
        combos.sort(key=lambda bits: abs(black_count(bits) - target_black))
        for bits in combos:
            black = _apply_bits(bits, groups, rows, cols)
            result = validate_skeleton(black, rows, cols)
            if result is None:
                continue
            across_slots, down_slots = result
            if not accept(across_slots, down_slots):
                continue
            found.append((black, across_slots, down_slots))
            if len(found) >= n_wanted:
                break
        return found

    rng = random.Random(seed)
    seen = set()
    for _ in range(tries):
        bits = tuple(1 if rng.random() < black_fraction else 0 for _ in groups)
        if bits in seen:
            continue
        seen.add(bits)
        black = _apply_bits(bits, groups, rows, cols)
        result = validate_skeleton(black, rows, cols)
        if result is None:
            continue
        across_slots, down_slots = result
        if not accept(across_slots, down_slots):
            continue
        found.append((black, across_slots, down_slots))
        if len(found) >= n_wanted:
            break
    return found


def is_interlocked(across_slots, down_slots):
    """True if every slot is connected to every other slot via shared
    cells (i.e. this is one genuine interlocking grid, not several
    independent sub-puzzles glued onto one sheet)."""
    slots = across_slots + down_slots
    if not slots:
        return False
    parent = list(range(len(slots)))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(x, y):
        rx, ry = find(x), find(y)
        if rx != ry:
            parent[rx] = ry

    cell_owner = {}
    for i, cells in enumerate(slots):
        for cell in cells:
            if cell in cell_owner:
                union(i, cell_owner[cell])
            else:
                cell_owner[cell] = i
    roots = {find(i) for i in range(len(slots))}
    return len(roots) == 1


def render(black, rows, cols):
    return "\n".join("".join("#" if black[r][c] else "." for c in range(cols)) for r in range(rows))
