# Screenshot mocks

Two sets, same three captions from the top-level README ("Screenshot captions"):

- `iphone-6.9/` — 1320x2868 (iPhone 6.9")
- `ipad-13/` — 2064x2752 (iPad 13", portrait, one-column play layout)

Mocks, not device captures: drawn from the real bundled puzzle `nankuro-v2-81dbdb7e0f43672a75fa`
(やさしい, 8x8) using the app's theme tokens, PlayLayout numbers (iPhone: 6-column tray, 50pt tiles;
iPad 13" portrait: NavigationSplitView with the 340pt puzzle-list sidebar, so the board pane is 692pt wide -> 82pt squares, 8-column tray of 64pt tiles; results appear as a 540pt iPad sheet) and Japanese strings. Replace with simulator/device
captures before submission.

| File | Caption | Scenario |
|---|---|---|
| `01-large-text-no-ads.png` | 広告なし。大きな文字でじっくり。 | Mid-game, nothing but board and tiles; used kanji dimmed |
| `02-tap-fills-same-number.png` | タップだけで、同じ番号をまとめて入力。 | Number 4 is in two squares; one tap on 面 fills both, its four words shown |
| `03-completed-board-and-words.png` | 完成盤も熟語も、あとからゆっくり確認。 | Results: stats, finished board, reading へきめん, all 14 words |

Regenerate: in `mock/`, `npm i playwright-core @fontsource/noto-serif-jp @fontsource/noto-sans-jp`, then `node render.mjs`.
