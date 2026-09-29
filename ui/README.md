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
| Undo / redo / check / hint / pause | native `toolbar`, `Button`, and `Menu` |
| Destructive restart | `confirmationDialog` |
| Completion result | `sheet` + system presentation detents |
| Stats / readings | `List`, `Form`, `LabeledContent` |
| Settings | `Form`, `Picker`, `Toggle` |
| First-launch tutorial | paged native `TabView` |
| Success feedback | `sensoryFeedback` |
| Accessibility | native controls + Dynamic Type/`@ScaledMetric` + explicit VoiceOver labels |
| App lifecycle timing | `scenePhase` |

The only custom presentation is the visual composition of a crossword square:
a rectangular cell with its clue number, entered kanji, selection state, and
starter state. Interaction semantics remain a SwiftUI `Button`.

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
- StoreKit is intentionally injected through `hasLifetimeUnlock` and
  `onUnlockRequested`; the UI does not invent entitlement state.
