# Screenshot mocks (iPhone 6.9", 1320x2868)

Mocks, not device captures. Drawn from the real bundled puzzle `nankuro-v2-81dbdb7e0f43672a75fa`
(やさしい, 8x8) using the app's theme tokens, layout numbers and Japanese strings.
Replace with authentic simulator/device captures before submission.

| File | README caption | Scenario |
|---|---|---|
| `01-large-text-no-ads.png` | 広告なし。大きな文字でじっくり。 | Mid-game, no ads/banners; big cells and 50pt tiles, used tiles dimmed |
| `02-tap-fills-same-number.png` | タップだけで、同じ番号をまとめて入力。 | Number 4 sits in two squares; one tap on 面 fills both; related words shown |
| `03-completed-board-and-words.png` | 完成盤も熟語も、あとからゆっくり確認。 | Finished board saved to 記録; results with readings (壁面 → へきめん) |

Regenerate: `npm i playwright-core @fontsource/noto-serif-jp @fontsource/noto-sans-jp` in `mock/`, then `node render.mjs`.
