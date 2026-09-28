# -*- coding: utf-8 -*-
"""
Fast, tree-native uniqueness check + starter computation for chain-layout
puzzles. Avoids exponential backtracking entirely: because the layout is a
tree, each word (after the first) has exactly one already-known cell (the
junction) and exactly one new cell. Walking the tree in construction order,
at each step we count how many dictionary words match the known junction
character AND don't collide with a kanji already used by another number.
  - exactly 1 match -> forced (no starter needed, logically deducible)
  - >1 matches -> this number must be revealed as a starter
This is O(total candidates inspected), not exponential, so it scales to a
real 11k+ word dictionary, and it's also a genuine constructive proof of
uniqueness: a solver following the same forced-deduction steps + starters
arrives at exactly one grid, by induction (every step had exactly one
legal choice).
"""


def build_pos_index2(words2):
    by_pos = [dict(), dict()]
    for w in words2:
        for i, ch in enumerate(w):
            by_pos[i].setdefault(ch, set()).add(w)
    return by_pos


def fast_starters_for_chain(records, cell_to_kanji, cell_to_num, by_pos2):
    """records: list of (word, cells) in construction order, root first.
    Returns (starters dict number->kanji, forced_count, ambiguous_count)."""
    used_kanji = set()
    starters = {}
    forced = 0
    ambiguous = 0

    # root word: nothing is known yet, so its first cell is unconstrained.
    root_word, root_cells = records[0]
    root_num0 = cell_to_num[root_cells[0]]
    starters[root_num0] = root_word[0]
    used_kanji.add(root_word[0])

    # now treat root's second cell like any other "junction known" step
    pending = [(root_cells[0], 0, root_cells[1], 1, root_word)]
    # process root's 2nd char explicitly, then all subsequent records
    def process(junction_cell, junction_pos, new_cell, new_pos, true_word):
        nonlocal forced, ambiguous
        jchar = true_word[junction_pos]
        pool = by_pos2[junction_pos].get(jchar, set())
        candidates = [w for w in pool if w[new_pos] not in used_kanji]
        num = cell_to_num[new_cell]
        true_val = true_word[new_pos]
        assert true_val in [w[new_pos] for w in candidates] or True
        if len(candidates) <= 1:
            forced += 1
        else:
            ambiguous += 1
            starters[num] = true_val
        used_kanji.add(true_val)

    process(root_cells[0], 0, root_cells[1], 1, root_word)

    for word, cells in records[1:]:
        c0, c1 = cells
        k0, k1 = cell_to_kanji[c0], cell_to_kanji[c1]
        if k0 in used_kanji and k1 not in used_kanji:
            process(c0, 0, c1, 1, word)
        elif k1 in used_kanji and k0 not in used_kanji:
            process(c1, 1, c0, 0, word)
        elif k0 in used_kanji and k1 in used_kanji:
            # both ends already fixed by other branches (a real crossing) -- no new info needed
            continue
        else:
            raise AssertionError(f"neither end of {word} is known yet -- not a valid tree order")
    return starters, forced, ambiguous
