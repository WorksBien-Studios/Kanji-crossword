# Dictionary data attribution

`filtered_common_words_v2.json` is a filtered word list **derived from
JMdict/EDICT**, property of the Electronic Dictionary Research and
Development Group (EDRDG), used under the **Creative Commons
Attribution-ShareAlike Licence (CC BY-SA), version 3.0**.

- Source project: http://www.edrdg.org/
- Licence: https://creativecommons.org/licenses/by-sa/3.0/

## What was kept from JMdict, and what wasn't

Only **words and their readings** (linguistic facts) were extracted.
English glosses are retained in this file for internal development
reference only (`gloss` field) — they are never surfaced to end users and
are not the source of the puzzle explanations shown in the app, which
must be original Japanese text per the product spec.

## Regenerating this file

The raw JMdict database used here was obtained via the `jamdict-data`
PyPI package (`pip install jamdict-data`), which bundles a compiled
SQLite version of JMdict under the same EDRDG licence terms (see that
package's own `LICENSE.md` for the EDRDG licence text in full). The raw
`jamdict.db` (~325MB) is not checked into this repo. `extract_jmdict.py`
in this directory's parent documents the exact extraction query used to
produce `filtered_common_words_v2.json` from that database.

## Obligation if you redistribute this file or a derivative of it

Per CC BY-SA: keep this attribution notice, and if you publish a
modified/derived version of the word list itself, license that
derivative under CC BY-SA (or a compatible licence) as well. This
requirement applies to the *word list*, not to the puzzle content or app
code built on top of it.
