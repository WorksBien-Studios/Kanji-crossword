# Japan iOS Puzzle Games — Recommended Opportunity

Research date: 2026-09-26; live App Store refresh: 2026-09-28  
Market: Japan iPhone App Store  
Lane: Japanese word and number-crossword puzzle games

## 漢字ナンクロ・広告なし — Kanji Number Crossword: No Ads

**Verdict: the strongest buildable opportunity in Japanese puzzle games.**

A calm, offline kanji number-crossword game for adults and seniors, sold as a one-time purchase. It combines carefully checked Japanese vocabulary, genuinely adjustable difficulty, large readable controls, uninterrupted play, and a proper completion/review sequence.

The product is not “another free kanji puzzle.” Its wedge is **magazine-quality puzzles without advertising, tracking, tiny text, or disposable completion screens**.

### Why demand is validated

- **漢字ナンクロ・クロスワード 毎日追加の脳トレパズル** (**Kanji Number Crosswords & Crosswords: Daily Brain Puzzles**) has **4.3 stars from roughly 21,000 ratings**. Its listing reports more than 30,000 puzzles, validating sustained demand for this exact Japanese format.
- A review dated 2025-10-23 says the user likes the app and its input design but now plays less because every completed puzzle triggers a long advertisement. The reviewer explicitly says they would pay **about ¥1,000** for an ad-free mode.
- **脳トレ！大人の漢字ナンクロ** (**Adult Kanji Number Crossword**) has **4.2 stars from 4,515 ratings**. Reviews praise sensible vocabulary and one-tap word learning, but request that the finished grid remain visible instead of immediately switching screens, that completion time be scored, and that legitimate alternate solutions be accepted.
- **漢字ナンクロPro 全5種の本格漢字パズル** (**Kanji Number Crossword Pro: Five Puzzle Types**) has **4.2 stars from 2,332 ratings**. Reviews complain about forced 30-second advertisements, text being too small, advertising that opens the Store unexpectedly, and difficulty that is sometimes too low.
- **漢字クロスワード パズル - 脳トレ人気アプリ** (**Kanji Crossword Puzzle: Popular Brain Training**) has **4.1 stars from 2,356 ratings**. A current surfaced review describes the experience as roughly **20% quiz and 80% advertising**.
- Reviews repeatedly mention older players: one 92-year-old reports playing daily, another reviewer plays with an elderly mother, and couples describe solving together. Readability and interruption-free play therefore affect the core audience rather than an edge case.

### Product promise

**広告なし。大きな文字で、毎日じっくり漢字ナンクロ。**  
No ads. Large, readable kanji puzzles you can enjoy at your own pace.

### MVP gameplay

1. Choose Easy, Standard, Hard, or Expert; difficulty must reflect reasoning depth and clue scarcity, not merely a larger grid.
2. Tap a numbered square to highlight every matching square.
3. Choose a kanji from the answer tray or enter it with a large native input panel.
4. Use unlimited undo and optional hints; mistakes never erase unrelated progress.
5. Autosave after every move and resume at the exact board position.
6. On completion, keep the finished grid on screen until the player chooses to continue.
7. Then show completion time, hints used, corrections, personal best, and all completed words.
8. Tap a completed word to see its verified reading. Concise Japanese explanations are deferred until separately authored and editorially checked; v1 does not fabricate definitions.
9. Add the result to an offline calendar and continue to the next puzzle.

### Required differentiation

- No advertising SDK, tracking, account, consumable currency, lives, or forced video.
- Large-text mode, pinch-to-zoom board, high contrast, landscape support, and spacious tap targets.
- Three useful board sizes rather than making advanced players use unreadably small squares.
- Untimed play by default; optional timer and personal-best mode for players who want competition.
- Completed-board pause before results, with a permanent archive of solved grids.
- Alternative-solution validation: if more than one legitimate word arrangement satisfies the grid, every validated arrangement must be accepted.
- Regionally narrow, obsolete, violent, or unnatural vocabulary excluded unless clearly labelled in Expert mode.
- Difficulty based on a solver score: number of forced moves, branching choices, word familiarity, and provided starter letters.
- V1 word review ships verified readings only. Explanations may be added later only from original, separately reviewed copy or properly licensed open data; never copy commercial dictionary definitions.
- Local-first storage with native device backup where enabled.
- Offline daily puzzle generated from a bundled, versioned puzzle set—no server dependency.

### Content and quality engine

Content quality is the moat and the principal risk. Every published puzzle should pass an automated and editorial pipeline:

1. Normalize readings, variants, old forms, and permitted character set.
2. Reject duplicate, offensive, highly regional, and context-dependent entries.
3. Generate candidate grids from the approved word graph.
4. Solve each grid exhaustively to detect zero-solution and multiple-solution cases.
5. Score logical difficulty independently from grid size.
6. Verify every shipped word and reading through the release validator and editorial review. Explanations are not part of v1 until separately authored and checked.
7. Store a versioned SHA-256 puzzle manifest so an update cannot silently alter an in-progress grid.

Launch with **300–500 fully reviewed puzzles**, not thousands of weak generated puzzles. The promise is trustworthy quality and calm play, not the largest headline number.

### Supply check and wedge

The relevant search results contain several high-volume kanji puzzle products, but the leaders are overwhelmingly free and advertising-supported. Even products using “Pro” positioning remain free, collect advertising-related data, and surface complaints about forced videos or Store redirects. The paid Puzzle chart does not show a meaningful kanji-number-crossword leader.

One competitor is praised for restrained advertising and a curated set of 255 puzzles, but its reviews still describe advertisements and unresolved completion-flow issues. Another offers enormous volume and daily additions but has the explicit ¥1,000 ad-removal request. The missing combination is therefore clear:

**large, carefully validated library + senior-readable interface + permanent completion history + zero advertising + one-time ownership.**

### Monetization

- Free: 30 complete puzzles spanning all launch modes and four difficulties, with no advertising.
- Lifetime unlock: **¥1,000** Japan price hypothesis, implemented as one non-consumable purchase and displayed in-app using StoreKit's localized live price.
- Lifetime includes the full launch library and all modes. History and statistics remain available to free users.
- Future themed puzzle packs can be separate permanent purchases only if they contain substantial newly reviewed content.
- After the fifth completion, show only a non-blocking unlock card on the result screen. Present the purchase sheet when the player deliberately opens a locked puzzle. Never interrupt an active puzzle.

### MVP boundary

Do not launch with multiplayer, chat, public leaderboards, subscriptions, prize draws, AI-generated live content, medical or dementia-prevention claims, or a server-fed daily puzzle. Do not bundle unrelated arithmetic, reflex, or picture puzzles.

**Native-AI clarification — 28 September 2026:** this excludes unverified *runtime* generation, not AI-assisted authoring. AI may propose candidate grids and content during production, but the fail-closed release validator must reject ambiguous, duplicate, structurally invalid, prohibited or stale content before bundling. V1 ships verified readings and deliberately omits unreviewed generated definitions.

The first version contains two validated modes: Kanji Number Crossword and Large Kanji Number Crossword. White Number Crossword remains a future variant because it requires distinct generation and validation rules; it must not be faked by relabelling an ordinary board.

### Opportunity score

**9.0/10** — excellent Japan-specific traffic, repeated recent pain, explicit willingness to pay at the proposed price, weak premium supply, manageable technology, and strong alignment with a private local-first product. The score is reduced because Japanese editorial accuracy is non-negotiable and direct competitors already possess very large puzzle libraries.

### Go/no-go criterion

Proceed only after the vocabulary policy is explicitly approved and **every shipped puzzle** passes exhaustive solution validation. AI-assisted review must be labelled accurately and must not be represented as native-linguist sign-off.

## Primary App Store evidence

- [Japan Puzzle chart](https://apps.apple.com/jp/iphone/charts/7012?chart=top-free)
- [漢字ナンクロ・クロスワード 毎日追加の脳トレパズル](https://apps.apple.com/jp/app/id714547064)
- [脳トレ！大人の漢字ナンクロ](https://apps.apple.com/jp/app/id1527701421)
- [漢字ナンクロPro 全5種の本格漢字パズル](https://apps.apple.com/jp/app/id1509623972)
- [漢字クロスワード パズル - 脳トレ人気アプリ](https://apps.apple.com/jp/app/id1449092401)

## Locked launch specification — 28 September 2026

### Commercial decision

| Item | Locked decision |
|---|---|
| App name | **漢字ナンクロ 広告なし** — *Kanji Number Crossword: No Ads* |
| Subtitle | **大きな文字でじっくり脳トレ** — *Large text for unhurried brain puzzles* |
| Primary category | Games → Word |
| Secondary category | Games → Puzzle |
| Launch market/language | Japan; Japanese UI and metadata |
| Devices | iPhone and iPad |
| Minimum OS | iOS/iPadOS 18.0 |
| Launch library | **360 exhaustively validated, AI-reviewed/owner-approved puzzles** |
| Free boundary | 30 complete puzzles across both launch modes and all four difficulty bands |
| Paid product | One non-consumable lifetime unlock; Japan launch price hypothesis **¥1,000** |
| Excluded | Advertising, subscriptions, consumable currency, accounts, tracking, live content service, runtime AI, leaderboards and multiplayer |

The earlier working name **漢字ナンクロ やさしい版** is rejected. It accurately signals accessibility but wrongly implies low difficulty. The live storefront shows strong demand from both older casual players and experienced players asking for harder puzzles. The locked name keeps the exact high-intent query and states the unmet paid benefit.

### Locked process flow

1. **First launch:** show one interactive three-step tutorial: tap a numbered square, choose a kanji, and see every matching number fill. Include `今すぐ始める` and keep `遊び方` permanently available.
2. **Play home:** show `続きから` first when a puzzle is active, otherwise `今日の一問`. Below it show the two launch modes—`漢字ナンクロ` and `大盤面`—plus progress and the next unfinished puzzle.
3. **Choose a puzzle:** select mode, then difficulty (`やさしい`, `ふつう`, `むずかしい`, `達人`). Difficulty is computed from logical branching, clue scarcity and word familiarity; board size is shown separately.
4. **Start immediately:** tapping an unlocked puzzle opens the board without a redundant confirmation screen. Tapping a locked puzzle opens the lifetime-unlock sheet.
5. **Solve:** tapping a numbered cell highlights every matching cell. Tapping a large shuffled kanji tile fills all matching cells. Dragging is never required. Optional keyboard entry is available in `達人` mode.
6. **Recover safely:** every move autosaves. Provide unlimited undo/redo, erase, pause and a deliberate `最初から` action with confirmation. A mistaken move never destroys unrelated progress.
7. **Help without punishment:** hints reveal one logically justified placement and explain why. Hints are unlimited but counted in the result. `間違いを確認` is user-triggered and never silently changes the board.
8. **Finish without losing the moment:** on completion, freeze the completed board, add a quiet haptic and show `完成盤を見る` / `結果を見る`. Never replace the board automatically.
9. **Results:** show time only when the timer was enabled, corrections, hints, checks, personal best and every completed word. A word opens its verified reading; definitions are deferred until separately editorially verified.
10. **Continue:** automatically archive the completed grid in the offline history calendar, then offer `次の問題` and `問題一覧へ` without requiring a separate save step.
11. **Purchase:** after the fifth free completion, add a non-blocking unlock card to results. The actual purchase sheet appears only after an explicit unlock action or selection of a locked puzzle. Include Restore Purchases and the StoreKit-localized price.

### Navigation and screen structure

- iPhone: iOS 18 `TabView` with **遊ぶ / 記録 / 設定**.
- iPad: the same tabs; **遊ぶ** and **記録** use `NavigationSplitView` so the puzzle list/history stays in the sidebar and the board/result appears in detail.
- Active play is a focused workspace. The board, kanji tray and essential controls stay on one screen; secondary settings live in a sheet.
- `設定` contains text size, contrast, haptics, timer default, Restore Purchases, privacy and licences. Mistake checking remains a deliberate in-game action. Reminders and manual export are deferred from v1.

### Content allocation

| Mode | Launch puzzles | Purpose |
|---|---:|---|
| 漢字ナンクロ | **240** (12–18 words) | Main progression across four solver-derived difficulty bands |
| 大盤面 | **120** (20–24 words) | Longer sessions with zoom and larger grids |
| **Total** | **360** | One exhaustively validated bundled library |

The 30-puzzle free set must sample both launch modes and every difficulty band. Puzzle ordering is finite and stable; `今日の一問` rotates locally through the bundled library and does not imply new server content.

### Reliability invariants

- Every shipped puzzle has exactly one accepted solution under the published rules. Zero-solution or multiple-solution candidates are rejected before bundling.
- The answer tray is shuffled and tested never to disclose the solution order.
- Difficulty is solver-derived, not inferred from grid dimensions alone.
- Progress writes atomically after every move and reopens at the exact board, zoom and selection state.
- Updating a puzzle pack cannot change an active or completed puzzle: save a content-addressed puzzle ID plus the immutable puzzle snapshot.
- Completion never dismisses the solved board automatically.
- Purchase, restore, pending, cancelled, failed, refunded, revoked and offline states never grant the wrong entitlement.
- No destructive action occurs without an explicit confirmation and a recoverable state.
- All tappable cells and controls have Japanese VoiceOver labels; large text and high-contrast modes cannot make the board unusable.

### Locked technology stack

| Layer | Choice |
|---|---|
| Domain engine | Pure Swift 6 package with no UI dependency; deterministic grid model, move reducer, solver, difficulty scorer, hint explainer and completion validator |
| Authoring pipeline | Swift command-line executable in the engine package; imports curated Japanese vocabulary, generates candidates, exhaustively solves them, assigns difficulty and emits canonical JSON |
| Content | Bundled, versioned `puzzles-v2.json` plus SHA-256 manifest; schema-v2 content-addressed IDs; no runtime generation or server fetch |
| UI | SwiftUI, iOS 18 `TabView`, `NavigationSplitView`, native sheets/alerts, `LazyVGrid`/`Grid` board with zoomable two-axis scrolling and semantic cell accessibility |
| State | Reducer-style immutable `GameState` and explicit actions; UI observes a single game session store |
| Persistence | SwiftData for progress, history, preferences and saved immutable puzzle snapshots; system device backup where enabled |
| Commerce | StoreKit 2 non-consumable lifetime unlock, verified transactions, current entitlements, a verified offline entitlement snapshot, restore path and StoreKit test configuration |
| Notifications | Not used in v1; no notification permission or push server |
| Platform features | `sensoryFeedback`, Dynamic Type, VoiceOver, high contrast and CryptoKit SHA-256 |
| Testing | Swift Testing for engine/property tests; XCUITest for tutorial, autosave/resume, completion, purchase/restore and iPhone/iPad navigation; CI on Linux for the pure engine and current stable Xcode on macOS for app builds |

Do not use SpriteKit, a third-party game engine, a database server, ad SDKs, analytics SDKs or Foundation Models at runtime. The interaction is grid-and-text based; native SwiftUI is simpler, more accessible and sufficient.

### Canonical puzzle JSON fields

Each schema-v2 puzzle record contains: `schemaVersion`, content-addressed `id`, `mode`, `difficulty`, `difficultyScore`, `difficultyMetrics`, `rows`, `columns`, immutable cell layout, number-to-kanji solution mapping, shuffled tray seed, starter cells, word spans/readings, editorial status, source/rights notes and `validationDigest`. V1 intentionally does not ship definitions. The release pipeline rejects unversioned/unknown fields, invalid cells or mappings, duplicate or prohibited vocabulary, missing/stale readings, non-content-addressed IDs, digest/manifest drift and any solver result other than exactly one solution.

### App Store listing — Japanese

Canonical non-media App Store Connect package: `app-store/APP_STORE_LISTING.md`.

**Name (11/30):** `漢字ナンクロ 広告なし`  
**Subtitle (13/30):** `大きな文字でじっくり脳トレ`  
**Keywords (92/100 UTF-8 bytes):** `シニア,頭の体操,熟語,クロスワード,語彙,暇つぶし,漢クロ,脳活,大人`

**Description:**

広告に邪魔されず、自分のペースでじっくり楽しめる漢字ナンクロです。

同じ番号のマスには同じ漢字が入ります。番号を選び、候補の漢字をタップするだけ。大きく見やすい文字とシンプルな操作で、初めての方も経験者も落ち着いて楽しめます。

【見やすく、迷わない】
・大きな文字と広いタップ範囲
・同じ番号のマスをまとめて強調
・拡大、縮小と高コントラスト表示
・ドラッグ不要のかんたん入力

【しっかり考えられる全360問】
・定番の漢字ナンクロ
・じっくり解ける大盤面
・解いた熟語の読みを確認できる復習
・やさしい、ふつう、むずかしい、達人の4段階

【途中でやめても安心】
・一手ごとの自動保存
・回数制限のない「元に戻す」「やり直す」
・考え方が分かるヒント
・いつでも続きから再開

【完成した盤面をゆっくり確認】
解き終わっても画面は勝手に切り替わりません。完成した盤面を見届けてから、記録や熟語の一覧へ進めます。熟語をタップすると、読み方を確認できます。

【広告なし。サブスクなし】
30問を無料でお試しいただけます。気に入ったら、一度の買い切りですべての問題、難易度、記録機能を利用できます。広告、コイン、回数制限はありません。

問題は端末に収録されているため、購入後はオフラインでも遊べます。アカウント登録も不要です。

### Screenshot captions

1. **広告なし。大きな文字でじっくり。**
2. **タップだけで、同じ番号をまとめて入力。**
3. **完成盤も熟語も、あとからゆっくり確認。**

**Screenshots to upload:** the finalised images for these captions are in [`app-store/screenshots/`](app-store/screenshots/README.md). Upload exactly these, in this order, as the App Store screenshots:

| Order | Caption | iPhone 6.9" (1320×2868) | iPad 13" (2064×2752) |
|---|---|---|---|
| 1 | 広告なし。大きな文字でじっくり。 | `app-store/screenshots/iphone-6.9/01-large-text-no-ads.png` | `app-store/screenshots/ipad-13/01-large-text-no-ads.png` |
| 2 | タップだけで、同じ番号をまとめて入力。 | `app-store/screenshots/iphone-6.9/02-tap-fills-same-number.png` | `app-store/screenshots/ipad-13/02-tap-fills-same-number.png` |
| 3 | 完成盤も熟語も、あとからゆっくり確認。 | `app-store/screenshots/iphone-6.9/03-completed-board-and-words.png` | `app-store/screenshots/ipad-13/03-completed-board-and-words.png` |

These are generated mocks built from the app code (see the screenshots README). `screenshots` in `app-store/LISTING_MANIFEST.json` is still empty and `upload_screenshots` is still `false`, so nothing is uploaded until that is changed deliberately.

### Draft status

**DRAFT_READY.** The product, flow, monetization hypothesis, metadata and technology are coherent. Before submission, the final binary must prove the 360-puzzle count, exhaustive release validation, accurately labelled editorial status, no-data/no-ad claims, StoreKit lifecycle behavior, authentic screenshots, support/privacy URLs and final App Store Connect values.
