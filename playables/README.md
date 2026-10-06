# Kanji Tiles (YouTube Playables)

A 3D kanji number-crossword for YouTube Playables: glossy mahjong-style tiles, a top-down camera,
a terrazzo table, one screen, no sound, and difficulty that adapts instead of being chosen.
The visual design was approved as an interactive mockup; this folder is the real project.

Uses a compact puzzle library, `../content/compact/puzzles-compact.json`, built by
`../engine/compact_pipeline.py`: dense 5x5 boards of 2- and 3-kanji words, 16-17 cells, 7-8
distinct kanji (repeated kanji share a number, as in the mockup), 259 puzzles, each proven
uniquely solvable. The main 360-puzzle release and the iOS app are untouched.

## Run it

```bash
cd playables
npm install
npm run dev          # builds src/generated/puzzles.json, then starts Vite
npm test             # game logic, adaptive difficulty, save parsing, library sanity
npm run build        # typecheck + production build into dist/
npm run shot         # headless-Chromium screenshots into shots/ (needs a build first)
node scripts/e2e.mjs # real pointer taps on four screen shapes (needs a build first)
```

Debug URL parameters: `?tut=0` skips the tutorial, `?p=40` picks a puzzle by index,
`?done=1` fills the board to show the completion flip, `?almost=1` leaves one slot.

## What is built

| Area | Where |
|---|---|
| Puzzle model, difficulty, one-to-one kanji mapping | `src/data.ts` |
| Game rules: select, place, hint (2 per puzzle), undo, skip, restart | `src/game.ts` |
| Adaptive difficulty: one skill value, small steps, an easier "breather" every 4th puzzle | `src/adaptive.ts` |
| Saving (progress, played list, in-progress puzzle, tutorial flag) | `src/save.ts` |
| YouTube Playables SDK wrapper with local fallbacks | `src/sdk.ts` |
| Bundled fonts | `src/fonts.ts`, `src/assets/fonts/` |
| Exact camera fit and one/two-column arrangement | `src/view/fit.ts`, `src/view/modes.ts` |
| Wiring, timer, tutorial, completion | `src/app.ts` |
| 3D scene: environment, terrazzo, camera fit | `src/view/stage.ts` |
| Layout that scales to any board and tray size | `src/view/layout.ts` |
| Tiles, keys, buttons, top bar, tutorial arrow, completion flip | `src/view/gameView.ts` |

Locked design: ivory-on-jade tiles, top-down view, light terrazzo table, mini-tile top bar,
balanced proportions, action tiles (teal, amber, vermilion) with large icons, large black corner
number on filled tiles, two-step wordless tutorial with a vermilion-on-ivory arrow, flip-tray
completion (time, hints, play bar), no stars, no sound, no menus.

## Scale on every screen

The world layout never changes: a 5x5 board (1.1 pitch), a 4x2 tray (1.4 pitch), three buttons and
a top bar, so every 7- or 8-kanji puzzle has identical dimensions. Only the camera changes, and it
is solved, not tuned (`src/view/fit.ts`): for each screen it finds the smallest camera distance at
which every corner of the content box stays inside the safe area (viewport minus notch insets and
a margin), at every pointer-parallax tilt the game can reach, and splits any spare height evenly.
Tall screens use one column; wide screens use two (board left, tray and buttons right), whichever
gives the larger scale (`src/view/modes.ts`, with a 4% margin so it does not flip while resizing).

`src/view/fit.test.ts` checks, on 25 screen shapes with and without notches: every corner is
inside the safe area under Three.js's own projection at all nine extreme tilts; the fit is tight
(a camera 0.1% closer would clip); the content touches the limiting edge; the arrangement with
the larger scale is always chosen; and minimum sizes hold. Sizes in CSS pixels:

| Screen | Layout | Board tile | Key | Button |
|---|---|---|---|---|
| 320x568 (small phone) | one column | 36 | 45 | 39 |
| 360x640 | one column | 41 | 51 | 44 |
| 375x667 | one column | 43 | 53 | 46 |
| 390x844 (iPhone 14) | one column | 49 | 61 | 52 |
| 412x915 (Pixel 7) | one column | 52 | 64 | 55 |
| 430x932 | one column | 54 | 67 | 57 |
| 844x390 (phone, sideways) | two columns | 33 | 41 | 35 |
| 568x320 (small phone, sideways) | two columns | 28 | 35 | 30 |
| 768x1024 (iPad mini) | one column | 66 | 82 | 70 |
| 1280x720 (laptop) | two columns | 65 | 80 | 69 |
| 1920x1080 | two columns | 97 | 121 | 103 |
| 3440x1440 (ultrawide) | two columns | 129 | 161 | 138 |

Tiles never fall below 32 px (26 px on a screen with a side under 340 px). The camera cap on pixel
count keeps very large screens smooth. The only inputs not covered are devices whose real safe
area differs from what `env(safe-area-inset-*)` reports.

## Words, review and fonts

Every unique word in an earlier draft of the library (2,228 of them) was read, and `COMPACT_EXCLUDE`
in `engine/compact_pipeline.py` now removes 125 words for war and weapons, death and serious
illness, crime, sexual or derogatory meaning, religion, politics and territory, gambling and
alcohol, and names or awkward forms. Excluded words still count in the uniqueness check, so a
player who knows one cannot find a second valid answer. Records are honestly labelled
`automated_and_ai_review_pending_owner_approval`: this was an AI-assisted review, not an editor's.

Fonts are bundled (`src/assets/fonts`, regenerated with `python3 scripts/build_fonts.py`): Shippori
Mincho 800 cut to the 563 kanji in the library (108 KB WOFF2) and Figtree 800 cut to digits and
the clock (1.5 KB). Both are SIL Open Font License 1.1; the licence texts sit beside them. The
build script fails if a kanji is missing from the font.

## Known gaps and open decisions

1. **Words:** reviewed by AI only. Anything you publish should still get a human read. The list
   of 125 exclusions is a starting point, not a guarantee.
2. **The YouTube SDK calls are unverified.** The docs site was not reachable when this was written.
   Names in `src/sdk.ts` come from memory; check them, and the size/loading limits, against the
   current Playables documentation before submitting.
3. **Not tried on a real phone.** Everything here ran in headless Chromium with software
   rendering; frame rate on real hardware is unmeasured.
4. **Placeholders:** 2 hints per puzzle; reset restarts the current puzzle with no confirmation;
   the adaptive step sizes and the "comfortable time" formula are untuned.
5. **Alternate answers:** uniqueness is proven against the 11,500-word common list. A real word
   outside that list could fit a board, and the game would not accept it.
6. **Colour pipeline.** Three.js colour management is switched off on purpose so the build
   matches the mockup's look (see the comment in `src/view/stage.ts`).
