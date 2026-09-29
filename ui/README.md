# Kanji Crossword iOS 18 UI

The app UI is built on the audited `lrodeveloperr/ios-18-shell` package at revision
`c082e90f9fc92970ef127792dfba2dd9cdffd710`. The shell owns top-level adaptive
navigation. Crossword-specific interactions use first-party SwiftUI components
rather than third-party UI libraries.

## Native component map

| Product need | Native implementation |
|---|---|
| Top-level Play / History / Settings | iOS 18 shell `AppShellView` + native `Tab` |
| iPhone/iPad adaptive master-detail | `NavigationSplitView` |
| Puzzle list / history | `List`, `Section`, `NavigationLink` |
| Mode / difficulty | segmented `Picker` |
| Empty / unavailable / locked states | `ContentUnavailableView` |
| Puzzle board | `Grid` + `GridRow`; each playable square is a native `Button` |
| Large board scrolling | two-axis `ScrollView` |
| Exact board restore | iOS 18 `ScrollPosition`, `ScrollGeometry`, `onScrollPhaseChange` |
| Pinch zoom | `MagnifyGesture` |
| Answer tray | adaptive `LazyVGrid` of native `Button` controls |
| Undo / redo / erase / check / hint / pause | native `toolbar`, `Button`, and `Menu` |
| Destructive restart | `confirmationDialog` |
| Completion result | `sheet` + system presentation detents |
| Stats / readings | `List`, `Form`, `LabeledContent` |
| Settings | `Form`, `Picker`, `Toggle` |
| Expert keyboard entry | native `TextField` in a system `Form` sheet |
| First-launch tutorial | paged `TabView` with native interactive `Grid`/`Button` controls |
| Lifetime unlock | StoreKit 2 `Product`, native purchase sheet, `Form`, and localized `displayPrice` |
| Restore Purchases | explicit native Settings `Button` calling `AppStore.sync()` through `KanjiCommerce` |
| Privacy policy | native `Link` in Settings to `https://worksbienstudios.com/apps/kanji-crossword/privacy/` |
| Licences / third-party notices | `LicensesView` (`Form`/`Section`) reachable via `NavigationLink` in Settings; JMdict/EDRDG CC BY-SA 3.0 attribution |
| Success feedback | `sensoryFeedback` |
| Accessibility | native controls + Dynamic Type/`@ScaledMetric` + explicit VoiceOver labels |
| App lifecycle timing | `scenePhase` |

The only custom presentation is the visual composition of a crossword square:
a rectangular cell with its clue number, entered kanji, selection state, and
starter state. Interaction semantics remain a SwiftUI `Button`.

## Visual design

The look is a paper puzzle magazine: ink on paper, Mincho kanji, indigo actions,
a highlighter-yellow selection and vermilion stamps. It is derived from the
audience analysis in `docs/ui-mock/index.html`, which is also the visual
reference for these screens.

| File | Role |
|---|---|
| `Theme.swift` | Light/dark colour tokens, kanji font, primary/secondary/tile/action button styles, `StampMark`, `KanjiCard` |
| `BoardInsights.swift` | Pure helpers: words a square belongs to, related squares, month grid, era date |
| `MiniBoardView.swift` | Non-interactive board picture for thumbnails and word review |
| `GameView.swift` | Strip (words or inline banner), board, labelled action bar, tray. Side panel layout at 720pt and wider |

Rules that came out of the analysis:

- No icon-only controls. Undo, redo, hint, check and erase are five labelled
  buttons under the board; the toolbar keeps only 休む and a その他 menu.
- Hint and check results are an inline banner, never an alert that covers the
  board. Squares flagged by a check get a dashed border and a "?" so colour is
  not the only cue.
- The board fits the pane at zoom 1. Pinch or the text-size setting enlarges it.
  Empty space is paper; only playable squares are drawn.
- Selecting a square lights every square that shares its number and softly tints
  the other squares in its words. Most puzzles never repeat a number, so the
  connected-words strip is what carries the help.
- The tab bar is hidden while playing on compact width.
- The records tab is a stamp calendar. It shows days played, never a streak.

## Design rules

- No third-party UI dependency is introduced.
- System Dynamic Type continues to work; the in-app text-size preference is
  additive rather than replacing accessibility text sizing.
- A selected square is differentiated by border weight as well as tint so color
  is not the only signal.
- The answer tray uses a lazy adaptive grid because its number of buttons and
  width change dynamically. The finite puzzle board itself uses non-lazy
  `Grid`, matching Apple's guidance to prefer the standard container until
  profiling proves laziness is needed.
- Scroll position is written only when scrolling settles, avoiding SwiftData
  writes for every scrolling frame.
- The UI never mutates `GameState` or SwiftData directly. All game actions go
  through `GameSessionViewModel` -> `PersistentGameSession` -> reducer +
  write-through persistence.
- StoreKit access comes only from the shared `LifetimePurchaseStore`.
  Locked-puzzle taps open the native unlock sheet; completion five and later
  shows a non-blocking result card; Settings contains explicit restore.
- Price text always comes from StoreKit's localized `Product.displayPrice`.
  The UI does not hard-code ¥1,000.


## Policy links

The canonical privacy policy is:

`https://worksbienstudios.com/apps/kanji-crossword/privacy/`

The URL is defined once in `PolicyLinks.swift` and surfaced in Settings with a native SwiftUI `Link` so the in-app policy and App Store Connect URL cannot drift.

The JMdict/EDRDG attribution required by `engine/data/ATTRIBUTION.md` and the app's Content Rights declaration is surfaced the same way: `LicensesView` reads the same `PolicyLinks.swift` URLs (`jmdictProject`, `ccBySa30`) and is reachable from Settings via 設定 → プライバシーと法的情報 → ライセンス・第三者表記.
