# Nankuro generator + solver engine (Python prototype)

This is a working, verified generator and exhaustive solver for the kanji
number-crossword (ナンクロ) puzzles described in the top-level `README.md`.
It is a **Python prototype that validates the algorithm**, not the
production authoring pipeline the product spec locks in (a Swift 6
command-line tool with no runtime dependency). Porting the logic here to
Swift is separate, mechanical follow-up work.

## What's here

| File | Role |
|---|---|
| `vocab.py` | Small (81-word), fully hand-verified seed vocabulary. First proof of concept. |
| `vocab2.py` | Expanded (226-word) hand-curated vocabulary. |
| `vocab3.py` | Real-scale vocabulary (~9,900 two-kanji + ~1,600 three-kanji words) sourced from JMdict, with `content_exclude.py` applied. **This is the one the current pipeline uses.** |
| `content_exclude.py` | ~190 words removed after a language/content review pass -- see "Editorial status" below. Every entry has a comment explaining why. |
| `extract_jmdict.py` | Documents exactly how `data/filtered_common_words_v2.json` was derived from the JMdict database (not runnable standalone here -- see `data/ATTRIBUTION.md`). |
| `grid.py` | Crossword skeleton generation (black/white cell patterns) and validation for dense, double-checked grids. |
| `csp.py` | Generic slot-based constraint solver: fills a skeleton from a dictionary, and exhaustively proves whether a given numbering + starter reveal has a **unique** solution. |
| `engine.py` | The first working generator: dense 2x2 "word square" puzzles (every cell double-checked). Good for small/easy puzzles; doesn't scale well with vocabulary size (see below). |
| `chain_layout.py` | The generator that actually scales: builds one large, genuinely connected puzzle by chaining words at shared kanji (mostly single-checked cells, a few real junctions) -- much closer to how real large ナンクロ boards look, and needs far less vocabulary density than a dense crossword. |
| `fast_tree.py` | Fast (non-exponential) uniqueness proof for chain-layout puzzles, using the **real nankuro solving model**: the player gets a tray of the exact kanji in play and must deduce the assignment among those, not search the whole dictionary. Cross-validated against the slow exhaustive solver in `csp.py` with zero disagreements. |
| `partition.py` | Carves the vocabulary into many **non-overlapping** puzzles (no word reused across the library) by repeatedly growing a chain and removing its words from the pool. |
| `final_pipeline.py` | Orchestrates all of the above end to end and emits canonical puzzle JSON records (see `content/`). |
| `run_v2.py`, `export_chain.py` | Earlier exploratory runners, kept for reference. |

## Running it

Pure standard-library Python 3, no dependencies:

```
cd engine
python3 final_pipeline.py
```

This takes ~3 minutes (the partition step is the bulk of it) and writes
`puzzles_jmdict_full_library.json` / `puzzles_jmdict_sample.json` into the
current directory -- copy or symlink them into `content/` if regenerating.

## Key design decision: tray-restricted solving

Early versions of the uniqueness check searched the *entire* dictionary
for competing solutions, which is wrong: real nankuro gives the player a
shuffled tray containing exactly the kanji in play. Modeling that
correctly (only words composable from the puzzle's own tray are
candidates) took the average required starter-reveal ratio from ~95% of
cells (a puzzle that gives away almost everything) down to ~26% (a real
logic puzzle). This is implemented in `final_pipeline.py` /
`fast_tree.py`.

## Numbers, as of the last generation run

- **301 puzzles**, sizes 12-45 words each, average 30 words/puzzle.
- Built from a real filtered JMdict vocabulary (~11,500 words after
  quality review), partitioned so **no word is reused across the
  library**.
- Every puzzle is spot-verified against the slow, exhaustive
  `csp.Solver` (not just the fast heuristic) with zero failures found in
  spot checks.
- Difficulty spread: 81 easy / 57 standard / 33 hard / 130 expert.

## Editorial status

Every generated record carries `editorialStatus: "localisation_review_passed"`
and an `editorialNotes` field describing exactly what that means: **this
was a localisation review performed by Claude (AI), not a native-speaker
linguist** -- no native reviewer was available for this project. The
review covered: automated JMdict common-word/POS/content filtering, a fix
for an entry-grouping bug in the raw extraction (see `extract_jmdict.py`),
an exhaustive manual pass over every word containing a
violence/weapon/death/crime/exploitation-associated kanji, an exhaustive
check against known defunct Japanese government ministry names, and
broad (not exhaustive, ~8% of the corpus) sampling for reading
correctness and natural phrasing. The project owner reviewed this record
and approved it in place of native sign-off. Read `editorialNotes` on any
record before treating its content as fully vetted.
