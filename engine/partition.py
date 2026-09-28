# -*- coding: utf-8 -*-
"""
Empirically measure the maximum number of NON-OVERLAPPING puzzles (no word
reused anywhere across the library) obtainable from the real JMdict-derived
dictionary, by repeatedly growing a chain puzzle and then permanently
removing every word it consumed from the pool before growing the next one.
"""
import random
from chain_layout import build_graph, grow_chain_grid
from vocab3 import WORDS2


def partition_all(words2, min_words=12, max_words=45, seed=0, max_puzzles=2000,
                   max_consecutive_stalls=3000):
    rng = random.Random(seed)
    remaining = list(words2)
    blacklisted_starts = set()  # failed as a start, but still usable as a child elsewhere
    puzzles = []
    stalls = 0
    while len(puzzles) < max_puzzles:
        startable = [t for t in remaining if t[0] not in blacklisted_starts]
        if not startable:
            break
        graph = build_graph(remaining)  # full remaining pool available as children
        start_word = startable[rng.randrange(len(startable))][0]
        occupied, slots, records = grow_chain_grid(start_word, graph, max_words=max_words, seed=rng.randrange(1_000_000))
        used_words = set(w for w, _ in records)
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
    puzzles, remaining = partition_all(WORDS2, min_words=12, max_words=45, seed=42)
    sizes = [len(r) for _, _, r in puzzles]
    total_words_used = sum(sizes)
    print(f"Non-overlapping puzzles carved out: {len(puzzles)}")
    print(f"Total words consumed: {total_words_used} / {len(WORDS2)}")
    print(f"Words left unused (too fragmented to form a puzzle >= 12 words): {len(remaining)}")
    print(f"Puzzle size distribution: min={min(sizes)} max={max(sizes)} avg={total_words_used/len(sizes):.1f}")
    import collections
    buckets = collections.Counter()
    for s in sizes:
        if s < 15: buckets["12-14"] += 1
        elif s < 25: buckets["15-24"] += 1
        elif s < 35: buckets["25-34"] += 1
        else: buckets["35-45"] += 1
    print("size buckets:", dict(buckets))
