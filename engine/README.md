# Nankuro generator + solver engine

This directory contains the production-authoring prototype for the offline kanji
number-crossword library. The runtime app remains local-first; puzzle generation
and validation happen before bundling.

## Release pipeline

`final_pipeline.py` now fails closed. A release is emitted only when all of the
following hold:

- exactly **360** non-overlapping puzzles are generated;
- every puzzle receives a schema-v2 **content-addressed ID** derived from its
  gameplay payload rather than a sequential number;
- every puzzle is solved again by the slow CSP verifier, with dictionary-word
  reuse allowed, and must have exactly one solution matching the shipped mapping;
- every grid is connected and is produced by the compact-placement generator;
- difficulty is derived from clue scarcity, logical distance and lexical
  branching pressure, not board dimensions;
- all emitted JSON is then re-read by `release_validator.py`, including schema,
  readings, prohibited-word checks, digests and the manifest.

The generated files are written directly to `content/`.

## Main files

| File | Role |
|---|---|
| `vocab3.py` | Filtered JMdict-derived two- and three-kanji vocabulary. |
| `content_exclude.py` | Explicit content/orthography exclusion list. |
| `chain_layout.py` | Connected compact board generator; placement scoring minimizes bounding-box waste. |
| `fast_tree.py` | Fast starter computation. It now fails if the true generated value disappears from the candidate pool. |
| `csp.py` | Independent exhaustive constraint solver used as the release authority. |
| `difficulty.py` | Solver-derived difficulty metrics. |
| `schema_v2.py` | Canonical schema, content addressing and digest helpers. |
| `partition.py` | Builds 360 non-overlapping puzzles without reusing vocabulary. |
| `release_validator.py` | Strict final gate for schema, structure, content, digests and exhaustive uniqueness. |
| `final_pipeline.py` | End-to-end generator + exhaustive verification + export. |

## Running locally

```bash
python3 engine/final_pipeline.py --output-dir content
python3 -m unittest discover -s tests -v
```

The GitHub Actions workflow runs the same pipeline and regression suite. On
branch pushes it commits regenerated canonical content when the generator output
changes.

## Content and editorial status

The vocabulary is derived from JMdict under its documented licence and filtered
for common usage, part of speech, risky content, outdated terms and unnatural
orthography. The shipped record uses
`editorialStatus: "ai_review_passed_owner_approved"`: this accurately records
AI-assisted localisation/content review approved by the project owner and does
**not** claim native-linguist sign-off.

Launch v1 intentionally exposes the verified reading for each word but does not
ship fabricated Japanese definitions. Concise explanations remain deferred
until they can be separately authored and editorially checked.
