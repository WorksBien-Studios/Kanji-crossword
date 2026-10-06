#!/usr/bin/env python3
"""Cut the two fonts down to the characters the game draws and write them as WOFF2.

Shippori Mincho 800 for kanji, Figtree 800 for digits and the clock. Both are SIL Open Font
License 1.1; the licence texts are copied next to the fonts. Needs: pip install fonttools brotli.
Run from playables/ after `npm install` and `npm run puzzles`:

    python3 scripts/build_fonts.py
"""
import json
import os
import shutil
import sys

from fontTools import subset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "src", "assets", "fonts")
NM = os.path.join(ROOT, "node_modules", "@expo-google-fonts")


def kanji_in_library():
    with open(os.path.join(ROOT, "src", "generated", "puzzles.json"), encoding="utf-8") as handle:
        puzzles = json.load(handle)
    chars = set()
    for p in puzzles:
        chars.update("".join(p["t"]))
        chars.update("".join(p["k"].values()))
    return chars


def build(src, name, text):
    from fontTools.ttLib import TTFont
    cmap = TTFont(src).getBestCmap()
    missing = [c for c in text if ord(c) not in cmap]
    if missing:
        sys.exit(f"{name}: the font has no glyph for {''.join(missing)}")
    opts = subset.Options()
    opts.flavor = "woff2"
    opts.layout_features = []
    opts.hinting = False
    opts.desubroutinize = True
    opts.notdef_outline = True
    opts.name_IDs = [0, 1, 2, 3, 4, 5, 6, 13, 14]
    font = subset.load_font(src, opts)
    sub = subset.Subsetter(opts)
    sub.populate(text=text)
    sub.subset(font)
    path = os.path.join(OUT, name)
    subset.save_font(font, path, opts)
    kb = os.path.getsize(path) / 1024
    print(f"{name}: {len(text)} characters, {kb:.0f} KB")
    return kb


def main():
    os.makedirs(OUT, exist_ok=True)
    kanji = kanji_in_library()
    # Everything drawn in the Mincho face: kanji only. Digits, the clock and the hint badge use Figtree.
    build(os.path.join(NM, "shippori-mincho", "800ExtraBold", "ShipporiMincho_800ExtraBold.ttf"), "shippori-mincho-800.woff2", "".join(sorted(kanji)))
    build(os.path.join(NM, "figtree", "800ExtraBold", "Figtree_800ExtraBold.ttf"), "figtree-800.woff2", "0123456789: ")
    shutil.copy(os.path.join(NM, "shippori-mincho", "LICENSE_FONT"), os.path.join(OUT, "OFL-ShipporiMincho.txt"))
    shutil.copy(os.path.join(NM, "figtree", "LICENSE_FONT") if os.path.exists(os.path.join(NM, "figtree", "LICENSE_FONT")) else os.path.join(NM, "figtree", "LICENSE"), os.path.join(OUT, "OFL-Figtree.txt"))
    print(f"kanji in the library: {len(kanji)}")


if __name__ == "__main__":
    sys.exit(main())
