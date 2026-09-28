# Generated puzzle content (prototype)

- `puzzles-v1.json` -- the full library: **301 puzzles**, produced by
  `engine/final_pipeline.py`. Each record matches the canonical puzzle
  JSON schema in the top-level `README.md` (`schemaVersion`, `id`, `mode`,
  `difficulty`, cell layout, solution, starter cells, word spans,
  `validationDigest`, etc.).
- `puzzles-v1-sample.json` -- a 5-puzzle size-diverse sample, for quick
  inspection without loading the full 2.6MB file.
- `manifest.json` -- `{id, sha256}` pairs for every puzzle in
  `puzzles-v1.json`, matching the product spec's requirement for "a
  versioned SHA-256 puzzle manifest so an update cannot silently alter an
  in-progress grid."

Read `engine/README.md`'s "Editorial status" section before treating this
content as fully vetted -- every record's own `editorialStatus` /
`editorialNotes` fields carry the same information.

To regenerate: `cd engine && python3 final_pipeline.py`, then copy its
output here.
