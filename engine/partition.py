# -*- coding: utf-8 -*-
"""Partition the reviewed vocabulary into non-overlapping puzzle boards."""
import random

from chain_layout import build_graph, grow_chain_grid
from vocab3 import WORDS2


def partition_all(
    words2,
    min_words=12,
    max_words=30,
    seed=0,
    max_puzzles=360,
    max_consecutive_stalls=8000,
):
    rng = random.Random(seed)
    remaining = list(words2)
    blacklisted_starts = set()
    puzzles = []
    stalls = 0
    while len(puzzles) < max_puzzles:
        startable = [t for t in remaining if t[0] not in blacklisted_starts]
        if not startable:
            break
        graph = build_graph(remaining)
        start_word = startable[rng.randrange(len(startable))][0]
        occupied, slots, records = grow_chain_grid(
            start_word,
            graph,
            max_words=max_words,
            seed=rng.randrange(1_000_000),
        )
        used_words = {w for w, _ in records}
        if len(records) < min_words:
            stalls += 1
            blacklisted_starts.add(start_word)
            if stalls > max_consecutive_stalls:
                break
            continue
        stalls = 0
        puzzles.append((occupied, slots, records))
        remaining = [t for t in remaining if t[0] not in used_words]
        blacklisted_starts -= used_words
    return puzzles, remaining


if __name__ == "__main__":
    puzzles, remaining = partition_all(WORDS2)
    sizes = [len(records) for _, _, records in puzzles]
    print(f"puzzles={len(puzzles)} used_words={sum(sizes)} remaining={len(remaining)}")
    if sizes:
        print(f"size min={min(sizes)} max={max(sizes)} avg={sum(sizes)/len(sizes):.1f}")
