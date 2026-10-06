# Kanji Tiles (YouTube Playables)

A 3D kanji number-crossword for YouTube Playables: glossy mahjong-style tiles, a top-down camera,
a terrazzo table, one screen, no sound, and difficulty that adapts instead of being chosen.
The visual design was approved as an interactive mockup; this folder is the real project.

Uses the validated puzzle library in `../content/` (built by `../engine/`). Nothing in the iOS app
or the Python engine was changed.

## Run it

```bash
cd playables
npm install
npm run dev          # builds src/generated/puzzles.json, then starts Vite
npm test             # game logic, adaptive difficulty, save parsing, library sanity
npm run build        # typecheck + production build into dist/
npm run shot         # headless-Chromium screenshots into shots/ (needs a build first)
node scripts/e2e.mjs # real pointer taps through the 3D scene (needs a build first)
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
| Wiring, timer, tutorial, completion | `src/app.ts` |
| 3D scene: environment, terrazzo, camera fit | `src/view/stage.ts` |
| Layout that scales to any board and tray size | `src/view/layout.ts` |
| Tiles, keys, buttons, top bar, tutorial arrow, completion flip | `src/view/gameView.ts` |

Locked design: ivory-on-jade tiles, top-down view, light terrazzo table, mini-tile top bar,
balanced proportions, action tiles (teal, amber, vermilion) with large icons, large black corner
number on filled tiles, two-step wordless tutorial with a vermilion-on-ivory arrow, flip-tray
completion (time, hints, play bar), no stars, no sound, no menus.

## Known gaps and open decisions

1. **Real puzzles do not look like the mockup board.** The mockup used a dense 5x5 board with
   8 kanji. The library's standard puzzles are diagonal chains: a 10x10 grid with about 19 open
   cells, and 17-19 kanji in the tray. The layout now spends the screen width on the board and
   uses a 3-row tray, which makes board tiles about 29 px on a 390x844 phone (keys about 42 px).
   That is close to the ceiling for a 10-column board; a 7x7 puzzle reaches about 40 px. Bigger
   needs smaller puzzles from the engine, or a zoomable board that pans to the selection.
2. **Large mode (13x13, up to 25 kanji) is not bundled.** `scripts/build-puzzles.mjs` only keeps
   `kanjiNankuro` (240 puzzles).
3. **No bundled kanji font.** The mockup loaded Shippori Mincho from Google Fonts; here the
   canvas falls back to the device's Japanese serif font, so glyph shapes vary by device. A
   subset font covering the library's kanji needs to be added.
4. **The Playables SDK calls are unverified.** The docs site was not reachable when this was
   written. Names in `src/sdk.ts` come from memory; check them, and the size/loading limits,
   against the current Playables documentation before submitting.
5. **Placeholders:** 2 hints per puzzle; reset restarts the current puzzle with no confirmation;
   the adaptive step sizes and the "comfortable time" formula are untuned.
6. **Colour pipeline.** Three.js colour management is switched off on purpose so the new build
   matches the mockup's look (see the comment in `src/view/stage.ts`).
7. **Performance not measured on real phones.** Only checked in headless Chromium with software
   rendering. Bundle is about 758 KB (188 KB gzipped) including the puzzle data.
