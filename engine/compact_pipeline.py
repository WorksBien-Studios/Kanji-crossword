# -*- coding: utf-8 -*-
"""Generate the compact 5x5 puzzle library used by the YouTube Playables game.

Dense boards of 2- and 3-kanji words in the classic number-crossword style: the same kanji sits in
several cells and shares one number, so a board has 16-18 cells but only 7-8 distinct kanji (an
8-key tray). Each board is built from a small cluster of related kanji, so every word on it is
made from that cluster.

It reuses the main release's vocabulary, difficulty metrics and exhaustive solver, but writes to
content/compact/ and never touches content/puzzles-v2.json or its manifest.

    python3 engine/compact_pipeline.py            # regenerate content/compact/puzzles-compact.json
    python3 engine/compact_pipeline.py --check    # validate the committed file
    python3 engine/compact_pipeline.py --count 60 # quick run, written to a temp path (not committed)
"""
from __future__ import annotations

import argparse
import collections
import json
import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from csp import Solver  # noqa: E402
from final_pipeline import _base_record, numbering_for  # noqa: E402
from schema_v2 import assign_difficulty_bands, content_id, validation_digest  # noqa: E402
from vocab3 import READING, WORDS_BY_LEN  # noqa: E402

MODE = "kanjiNankuroCompact"
N = 5
SEED = 2026
TARGET = 360
MAX_STARTERS = 3
MIN_CELLS = 15
TRAY_SIZES = (7, 8)
#: A word may appear in at most this many puzzles, and a kanji cluster in one.
MAX_WORD_USES = 2
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "content", "compact", "puzzles-compact.json")

W2, W3 = WORDS_BY_LEN[2], WORDS_BY_LEN[3]
BY_CHAR = collections.defaultdict(list)
for _w in W2 + W3:
    for _ch in set(_w):
        BY_CHAR[_ch].append(_w)
COMMON = sorted(ch for ch, ws in BY_CHAR.items() if len(ws) >= 10)


def runs_of(open_cells):
    out = []
    for r in range(N):
        run = []
        for c in range(N + 1):
            if c < N and (r, c) in open_cells:
                run.append((r, c))
            else:
                if len(run) >= 2:
                    out.append(run)
                run = []
    for c in range(N):
        run = []
        for r in range(N + 1):
            if r < N and (r, c) in open_cells:
                run.append((r, c))
            else:
                if len(run) >= 2:
                    out.append(run)
                run = []
    return out


def board_patterns(rng):
    """Block layouts where every run is 2-3 cells and every open cell is part of a word."""
    cells = [(r, c) for r in range(N) for c in range(N)]
    found = {}
    for blocks_n in (7, 8, 9):
        for _ in range(40000):
            blocks = frozenset(rng.sample(cells, blocks_n))
            open_cells = frozenset(cells) - blocks
            if len(open_cells) < MIN_CELLS:
                continue
            slots = runs_of(open_cells)
            if any(len(s) > 3 for s in slots):
                continue
            if {c for s in slots for c in s} != open_cells:
                continue
            found[blocks] = slots
    return [(sorted(b), s) for b, s in sorted(found.items(), key=lambda kv: sorted(kv[0]))]


def words_within(chars):
    seen, out = set(), []
    for ch in chars:
        for w in BY_CHAR[ch]:
            if w not in seen and set(w) <= chars:
                seen.add(w)
                out.append(w)
    return out


def grow_cluster(rng, size):
    """Grow a set of kanji that form many words together."""
    chars = {rng.choice(COMMON)}
    common = set(COMMON)
    while len(chars) < size:
        neighbours = set()
        for m in chars:
            for w in BY_CHAR[m]:
                neighbours.update(ch for ch in w if ch not in chars and ch in common)
        scores = {}
        for ch in sorted(neighbours):
            gain = sum(1 for w in BY_CHAR[ch] if set(w) <= chars | {ch})
            if gain:
                scores[ch] = gain
        if not scores:
            return None
        picks, weights = zip(*scores.items())
        chars.add(rng.choices(picks, weights=[x * x for x in weights])[0])
    return chars


def verify_unique(slots, cell_to_num, starters, tray):
    r2 = [w for w in W2 if set(w) <= tray]
    r3 = [w for w in W3 if set(w) <= tray]
    solutions = Solver(slots, {2: r2, 3: r3}).count_with_numbering(cell_to_num, starters, cap=2, forbid_repeat=False)
    return len(solutions) == 1, solutions


def build_record(fill, slots):
    cell_to_num, num_to_kanji = numbering_for(fill)
    tray = set(fill.values())
    r2 = [w for w in W2 if set(w) <= tray]
    r3 = [w for w in W3 if set(w) <= tray]
    solver = Solver(slots, {2: r2, 3: r3})
    starters = solver.greedy_starters(cell_to_num, num_to_kanji, attempts=6, seed=1)
    if starters is None:
        return None
    if not starters:
        # Unique with no reveals is legal, but a board needs somewhere to start: reveal the kanji
        # that sits in the most cells.
        counts = collections.Counter(cell_to_num.values())
        num = sorted(counts, key=lambda n: (-counts[n], n))[0]
        starters = {num: num_to_kanji[num]}
    if len(starters) > MAX_STARTERS:
        return None
    ok, _ = verify_unique(slots, cell_to_num, starters, tray)
    if not ok:
        return None
    records = [("".join(fill[c] for c in run), run) for run in slots]
    record = _base_record(fill, records, cell_to_num, num_to_kanji, starters, r2)
    record["mode"] = MODE
    record["id"] = content_id(record)
    shuffled = list(num_to_kanji.values())
    random.Random(record["id"]).shuffle(shuffled)
    record["traySeed"] = shuffled
    return record


def candidates_for_seed(args):
    """Worker: build verified puzzle records for one seed. No cross-puzzle caps here; those are applied
    later when the parent picks a varied set."""
    seed, budget_s = args
    rng = random.Random(seed)
    patterns = board_patterns(random.Random(seed))
    out = {}
    started = time.time()
    while time.time() - started < budget_s:
        chars = grow_cluster(rng, rng.choice(TRAY_SIZES[1:] + (9,)))
        if not chars:
            continue
        ws = words_within(chars)
        wordset = set(ws)
        w2 = [w for w in ws if len(w) == 2]
        w3 = [w for w in ws if len(w) == 3]
        for blocks, slots in rng.sample(patterns, 120):
            if any(len(s) == 3 for s in slots) and not w3:
                continue
            fills = Solver(slots, {2: w2, 3: w3}).fill_all(max_count=4, forbid_repeat=True, rng=rng)
            for fill in fills:
                if len(fill) != len({c for s in slots for c in s}):
                    continue
                words = ["".join(fill[c] for c in run) for run in slots]
                # The solver does not re-check a slot whose letters are fully fixed by its crossings.
                if any(w not in wordset for w in words) or len(set(words)) != len(words):
                    continue
                if len(set(fill.values())) not in TRAY_SIZES:
                    continue
                record = build_record(fill, slots)
                if record is not None:
                    out[record["id"]] = record
                    break
    return list(out.values())


def pick_varied(candidates, target, seed=SEED):
    """Greedy pick: each kanji cluster once, each word at most MAX_WORD_USES times. Candidates built from
    the least-used words go first so the library stays varied."""
    rng = random.Random(seed)
    remaining = sorted(candidates, key=lambda r: r["id"])
    rng.shuffle(remaining)
    uses = collections.Counter()
    trays = set()
    picked = []
    while remaining and len(picked) < target:
        best_i, best_cost = None, None
        for i, rec in enumerate(remaining):
            words = [s["word"] for s in rec["wordSpans"]]
            if frozenset(rec["solution"].values()) in trays or any(uses[w] >= MAX_WORD_USES for w in words):
                continue
            cost = sum(uses[w] for w in words)
            if best_cost is None or cost < best_cost:
                best_i, best_cost = i, cost
                if cost == 0:
                    break
        if best_i is None:
            break
        rec = remaining.pop(best_i)
        picked.append(rec)
        trays.add(frozenset(rec["solution"].values()))
        uses.update(s["word"] for s in rec["wordSpans"])
    return picked


def generate(target=TARGET, seed=SEED, log=True, workers=None, seconds=120, return_pool=False):
    import multiprocessing as mp

    workers = workers or max(1, mp.cpu_count())
    started = time.time()
    with mp.Pool(workers) as pool:
        batches = pool.map(candidates_for_seed, [(seed * 1000 + i, seconds) for i in range(workers)])
    merged = {}
    for batch in batches:
        for rec in batch:
            merged[rec["id"]] = rec
    pool_list = list(merged.values())
    if log:
        print(f"  {len(pool_list)} verified candidates from {workers} workers in {time.time() - started:.0f}s", flush=True)
    records = pick_varied(pool_list, target, seed)
    if log:
        print(f"  picked {len(records)} varied puzzles (cap {MAX_WORD_USES} uses per word, one per kanji cluster)", flush=True)
    assign_difficulty_bands(records)
    for record in records:
        record["validationDigest"] = validation_digest(record)
    validate(records)
    return (records, pool_list) if return_pool else records


def validate(records):
    errors = []
    seen_ids, seen_trays = set(), set()
    uses = collections.Counter()
    for rec in records:
        rid = rec.get("id", "?")
        if rec["mode"] != MODE:
            errors.append(f"{rid}: wrong mode")
        if rid in seen_ids:
            errors.append(f"{rid}: duplicate id")
        seen_ids.add(rid)
        if rid != content_id(rec):
            errors.append(f"{rid}: content-addressed id mismatch")
        if rec["validationDigest"] != validation_digest(rec):
            errors.append(f"{rid}: digest mismatch")
        if rec["rows"] > N or rec["columns"] > N:
            errors.append(f"{rid}: board larger than {N}x{N}")
        nums = sorted(int(n) for n in rec["solution"])
        if nums != list(range(1, len(nums) + 1)):
            errors.append(f"{rid}: slot numbers are not 1..N")
        if len(nums) not in TRAY_SIZES:
            errors.append(f"{rid}: {len(nums)} kanji, expected {TRAY_SIZES}")
        if sorted(rec["traySeed"]) != sorted(rec["solution"].values()):
            errors.append(f"{rid}: tray does not match the solution")
        if len(set(rec["solution"].values())) != len(rec["solution"]):
            errors.append(f"{rid}: a kanji is mapped to two numbers")
        tray_key = frozenset(rec["solution"].values())
        if tray_key in seen_trays:
            errors.append(f"{rid}: kanji cluster reused")
        seen_trays.add(tray_key)
        if not 1 <= len(rec["starterCells"]) <= MAX_STARTERS:
            errors.append(f"{rid}: {len(rec['starterCells'])} starter cells")
        for num, kanji in rec["starterCells"].items():
            if rec["solution"].get(num) != kanji:
                errors.append(f"{rid}: starter {num} disagrees with the solution")

        cell_to_num = {tuple(int(x) for x in k.split(",")): n for k, n in rec["cellNumbers"].items()}
        open_cells = set(cell_to_num)
        layout_open = {(r, c) for r, row in enumerate(rec["cellLayout"]) for c, ch in enumerate(row) if ch == "."}
        if open_cells != layout_open:
            errors.append(f"{rid}: layout and numbering disagree")
        if len(open_cells) < MIN_CELLS:
            errors.append(f"{rid}: only {len(open_cells)} cells")
        grid = {cell: rec["solution"][str(n)] for cell, n in cell_to_num.items()}
        slots = [[tuple(int(x) for x in cell.split(",")) for cell in span["cells"]] for span in rec["wordSpans"]]
        derived = {frozenset(s) for s in runs_of_layout(open_cells)}
        if derived != {frozenset(s) for s in slots}:
            errors.append(f"{rid}: word spans do not match the board's runs")
        for span, cells in zip(rec["wordSpans"], slots):
            word = "".join(grid[c] for c in cells)
            if word != span["word"]:
                errors.append(f"{rid}: span {span['word']} does not read {word}")
            if len(word) not in (2, 3) or word not in READING or span["reading"] != READING[word]:
                errors.append(f"{rid}: unverified word or reading: {word}")
            uses[word] += 1
        tray = set(rec["solution"].values())
        starters = {int(n): k for n, k in rec["starterCells"].items()}
        ok, solutions = verify_unique(slots, cell_to_num, starters, tray)
        if not ok:
            errors.append(f"{rid}: {len(solutions)} solutions")
        elif any(solutions[0].get(c) != grid[c] for c in grid):
            errors.append(f"{rid}: unique solution differs from the shipped one")
    for word, n in uses.items():
        if n > MAX_WORD_USES:
            errors.append(f"word {word} used {n} times (max {MAX_WORD_USES})")
    if errors:
        raise RuntimeError("compact library invalid:\n  " + "\n  ".join(errors[:20]))


def runs_of_layout(open_cells):
    return runs_of(open_cells)


def summary(records):
    cells = collections.Counter(len(r["cellNumbers"]) for r in records)
    tray = collections.Counter(len(r["solution"]) for r in records)
    starters = collections.Counter(len(r["starterCells"]) for r in records)
    bands = collections.Counter(r["difficulty"] for r in records)
    return f"cells {sorted(cells.items())}, kanji {sorted(tray.items())}, starters {sorted(starters.items())}, bands {dict(bands)}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="validate the committed file only")
    parser.add_argument("--count", type=int, default=None, help="generate this many (to a temp file, for experiments)")
    parser.add_argument("--seconds", type=int, default=120, help="per-worker generation time budget")
    args = parser.parse_args()
    if args.check:
        with open(OUT, encoding="utf-8") as handle:
            records = json.load(handle)
        validate(records)
        print(f"compact library: {len(records)} puzzles valid\n{summary(records)}")
        return
    count = args.count or TARGET
    records = generate(count, seconds=args.seconds)
    path = OUT if args.count is None else "/tmp/puzzles-compact-experiment.json"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(records, handle, ensure_ascii=False, indent=1)
        handle.write("\n")
    print(f"wrote {len(records)} puzzles to {path}\n{summary(records)}")


if __name__ == "__main__":
    main()
