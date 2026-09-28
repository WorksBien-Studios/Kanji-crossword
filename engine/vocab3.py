# -*- coding: utf-8 -*-
"""
Real-scale vocabulary sourced from JMdict (EDRDG, CC BY-SA 3.0 license --
attribution required; see data/ATTRIBUTION.md).
Filtered to: pure-kanji jukugo, length 2-3, tagged as common
(news1/ichi1/spec1/spec2/gai1) AT THE SPECIFIC KANJI-SPELLING LEVEL (not
inherited from a sibling spelling under the same dictionary entry -- see
extract_jmdict.py for the bug this fixes), noun part-of-speech, and NOT
archaic/obsolete/vulgar/derogatory/slang/rare/proper-noun.

On top of the automated filters, a manual native-language-quality pass
(see content_exclude.py) removed entries found to be: graphic
violence/crime/exploitation that JMdict doesn't tag as such, non-standard
orthography (doubled kanji where native writing uses the 々 iteration
mark or kana), and a few dated/overly narrow terms. This is a thorough
review pass, not a substitute for the native Japanese editorial sign-off
the product spec requires before shipping.

English glosses from JMdict are kept in filtered_common_words_v2.json for
our OWN internal review only -- they are never surfaced to end users or
used as the shipped "explanation" text (the product spec requires
original Japanese explanations, verified by a native editor, not
dictionary definitions).
"""
import json
import os

from content_exclude import EXCLUDE_WORDS

_HERE = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(_HERE, "data", "filtered_common_words_v2.json"), encoding="utf-8") as f:
    _raw = json.load(f)

WORDS_BY_LEN = {}
READING = {}
GLOSS_INTERNAL_ONLY = {}
for length_str in ("2", "3"):
    words = []
    for e in _raw[length_str]:
        w = e["word"]
        if w in EXCLUDE_WORDS:
            continue
        words.append(w)
        READING[w] = e["reading"]
        GLOSS_INTERNAL_ONLY[w] = e["gloss"]
    WORDS_BY_LEN[int(length_str)] = words

WORDS2 = [(w, READING[w], None) for w in WORDS_BY_LEN[2]]
WORDS3 = [(w, READING[w], None) for w in WORDS_BY_LEN[3]]

DICTIONARY_ATTRIBUTION = (
    "Word list derived from JMdict/EDICT, property of the Electronic "
    "Dictionary Research and Development Group, used under CC BY-SA 3.0. "
    "http://www.edrdg.org/"
)
