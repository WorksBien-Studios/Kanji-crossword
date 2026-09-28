# -*- coding: utf-8 -*-
"""
Fast, tree-native starter computation for chain-layout Nankuro puzzles.

The algorithm walks the construction tree. Whenever the currently known
junction leaves more than one legal word under the tray-restricted
vocabulary, the new number is revealed as a starter. The slow CSP solver is
still the release authority and re-checks every emitted puzzle.
"""


def build_pos_index2(words2):
    by_pos = [dict(), dict()]
    for w in words2:
        for i, ch in enumerate(w):
            by_pos[i].setdefault(ch, set()).add(w)
    return by_pos


def fast_starters_for_chain(records, cell_to_kanji, cell_to_num, by_pos2):
    """Return (starters, forced_count, ambiguous_count), failing closed."""
    used_kanji = set()
    starters = {}
    forced = 0
    ambiguous = 0

    root_word, root_cells = records[0]
    root_num0 = cell_to_num[root_cells[0]]
    starters[root_num0] = root_word[0]
    used_kanji.add(root_word[0])

    def process(junction_cell, junction_pos, new_cell, new_pos, true_word):
        nonlocal forced, ambiguous
        jchar = true_word[junction_pos]
        if cell_to_kanji[junction_cell] != jchar:
            raise AssertionError(
                f"junction mismatch for {true_word}: grid has "
                f"{cell_to_kanji[junction_cell]!r}, word has {jchar!r}"
            )
        pool = by_pos2[junction_pos].get(jchar, set())
        candidates = [w for w in pool if w[new_pos] not in used_kanji]
        true_val = true_word[new_pos]
        legal_values = [w[new_pos] for w in candidates]
        if true_val not in legal_values:
            raise AssertionError(
                f"true value {true_val!r} for {true_word!r} disappeared "
                "from the tray-restricted candidate pool"
            )
        num = cell_to_num[new_cell]
        if len(candidates) == 1:
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
            continue
        else:
            raise AssertionError(
                f"neither end of {word} is known yet -- invalid construction order"
            )
    return starters, forced, ambiguous
