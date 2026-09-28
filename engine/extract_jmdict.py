# -*- coding: utf-8 -*-
"""
Reproduces data/filtered_common_words_v2.json from JMdict. Not meant to be
run standalone in this repo -- it needs a local jamdict.db, which is NOT
checked in here (see data/ATTRIBUTION.md for how to get it). Kept for
reproducibility and to document two real bugs an earlier, naive version
of this extraction had:

1. Priority ("common word") tags were aggregated at the idseq level, so if
   an idseq had multiple, UNRELATED kanji spellings (JMdict genuinely
   groups these together e.g. idseq 1000225 = 明白/偸閑/白地 all sharing
   the reading あからさま), any one spelling being tagged common leaked
   the tag onto ALL of them. Fixed: gate on the SPECIFIC Kanji row's own
   priority tag (join on Kanji.ID, not idseq).
2. The reading was just "the first Kana row for this idseq" -- fragile
   when an idseq has several readings. Fixed: prefer whichever Kana row
   itself carries a common-priority tag; fall back to first row only if
   none do.
"""
import sqlite3
import re
import json

CJK_ONLY = re.compile(r"^[一-鿿々]+$")
COMMON_TAGS = {"news1", "ichi1", "spec1", "spec2", "gai1"}
BAD_MISC = {
    "archaism", "obsolete term", "vulgar expression or word", "derogatory",
    "sensitive", "slang", "Internet slang", "rare", "obscure term",
    "manga slang", "place name", "full name of a particular person",
    "work of art, literature, music, etc. name", "historical term",
    "yojijukugo",
}

con = sqlite3.connect("jamdict.db")
cur = con.cursor()

# Kanji.ID -> tags (row-specific, NOT idseq-aggregated)
cur.execute("select k.ID, p.text from Kanji k join KJP p on p.kid = k.ID")
kanjiid_priority = {}
for kid, tag in cur.fetchall():
    kanjiid_priority.setdefault(kid, set()).add(tag)

# Kana.ID -> tags (row-specific)
cur.execute("select k.ID, p.text from Kana k join KNI p on p.kid = k.ID")
kanaid_priority = {}
for kid, tag in cur.fetchall():
    kanaid_priority.setdefault(kid, set()).add(tag)

cur.execute("select s.idseq, m.text from Sense s join misc m on m.sid = s.ID")
idseq_misc = {}
for idseq, tag in cur.fetchall():
    idseq_misc.setdefault(idseq, set()).add(tag)

cur.execute("select s.idseq, p.text from Sense s join pos p on p.sid = s.ID")
idseq_pos = {}
for idseq, tag in cur.fetchall():
    idseq_pos.setdefault(idseq, set()).add(tag)

# idseq -> list of (Kana.ID, text) in row order
cur.execute("select ID, idseq, text from Kana order by idseq, ID")
idseq_kanas = {}
for kid, idseq, text in cur.fetchall():
    idseq_kanas.setdefault(idseq, []).append((kid, text))

cur.execute("select s.idseq, g.text from Sense s join SenseGloss g on g.sid = s.ID where g.lang='eng'")
idseq_gloss = {}
for idseq, text in cur.fetchall():
    idseq_gloss.setdefault(idseq, []).append(text)

cur.execute("select ID, idseq, text from Kanji")
rows = cur.fetchall()

def pick_reading(idseq):
    kanas = idseq_kanas.get(idseq)
    if not kanas:
        return None
    for kid, text in kanas:
        if kanaid_priority.get(kid, set()) & COMMON_TAGS:
            return text
    return kanas[0][1]

results = {2: [], 3: [], 4: []}
seen_words = set()
rejected_due_to_row_level_fix = 0
for kid, idseq, text in rows:
    if len(text) not in (2, 3, 4):
        continue
    if not CJK_ONLY.match(text):
        continue
    if text in seen_words:
        continue
    tags = kanjiid_priority.get(kid, set())
    if not (tags & COMMON_TAGS):
        continue
    misc = idseq_misc.get(idseq, set())
    if misc & BAD_MISC:
        continue
    pos = idseq_pos.get(idseq, set())
    if not any("noun" in p.lower() for p in pos):
        continue
    reading = pick_reading(idseq)
    if not reading:
        continue
    if not re.match(r"^[ぁ-ゟ]+$", reading):
        continue
    seen_words.add(text)
    results[len(text)].append({
        "word": text, "reading": reading,
        "gloss": idseq_gloss.get(idseq, []),
    })

for n in (2, 3, 4):
    print(f"length {n}: {len(results[n])} common-tagged noun jukugo candidates (row-level fix)")

with open("filtered_common_words_v2.json", "w", encoding="utf-8") as f:
    json.dump(results, f, ensure_ascii=False, indent=1)
print("wrote filtered_common_words_v2.json")

# Report the specific bug case to confirm the fix worked
cur.execute("select idseq from Kanji where text=?", ("白地",))
print("白地 idseqs:", cur.fetchall())
in_v2 = [e for e in results[2] if e["word"] == "白地"]
print("白地 now in v2 list:", in_v2)
