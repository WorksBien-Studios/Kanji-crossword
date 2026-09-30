# Kanji Crossword production runtime

This Swift package is the production runtime boundary for the iOS/iPadOS 18 app. It intentionally does **not** generate puzzles. The Python authoring pipeline in `../engine/` remains the release authority for generating and exhaustively validating `../content/puzzles-v2.json`.

## Modules

- `KanjiGameCore` — pure Swift 6 domain logic with no UI or persistence dependency. It decodes schema-v2 puzzles, validates the runtime contract, owns `GameState`, applies explicit `GameAction`s through a deterministic reducer, handles undo/redo, mistakes, hints, completion, timer state, selection, and exact board viewport state.
- `KanjiPersistence` — SwiftData adapter for iOS 18/macOS 15. It stores active progress, completed-game history, preferences, and immutable puzzle snapshots. `GamePersistenceStore` is a `@ModelActor`, so all model-context access is serialized.
- `PersistentGameSession` — the write-through boundary used by the SwiftUI layer. A state-changing action is reduced first, persisted, and only then published as the in-memory state. A failed save therefore cannot silently advance the UI beyond disk state.
- `KanjiCommerce` — StoreKit 2 lifetime-unlock boundary. It loads the non-consumable, consumes only verified transactions, listens to `Transaction.updates`, derives online access from `Transaction.currentEntitlements`, responds to revocation/refund updates, exposes explicit Restore Purchases via `AppStore.sync()`, and maintains a Keychain snapshot only for previously verified offline access.

## Persistence invariants

- Active progress is unique per puzzle ID.
- Every active save contains both the versioned `GameState` and the immutable puzzle snapshot that session started with.
- Selection, zoom, board center, undo/redo stacks, timer accounting, hints, checks, and all entered kanji survive a relaunch.
- Completion archives the final state and puzzle snapshot and removes active progress in the same SwiftData save.
- Reopening an in-progress puzzle uses the saved snapshot, not a potentially changed bundled record.
- Completed sessions are keyed by session ID, allowing the same puzzle to be solved again in a later session without overwriting history.
- Large encoded state/snapshot blobs use SwiftData external storage.
- Settings are stored as a singleton SwiftData model.

## Commerce invariants

- Product ID: `com.gooduse.kanjicrossword.jp.pro.lifetime`.
- Product type: one non-consumable lifetime unlock.
- The UI never hard-codes a currency price; it displays `Product.displayPrice`.
- A pending, cancelled, failed, unknown, or unverified purchase never grants paid access.
- A verified purchase is persisted to the offline Keychain snapshot before the transaction is finished.
- If the Keychain write fails, the verified purchase remains available for the current process but the transaction is intentionally left unfinished so StoreKit can replay it later.
- A verified refund/revocation immediately clears the local entitlement.
- At launch, a previously verified offline snapshot can provisionally preserve access while StoreKit is unreachable. Once the product is successfully loaded from the App Store, an authoritative absence of the current entitlement clears any stale snapshot.
- `AppStore.sync()` is called only after an explicit user Restore Purchases action.
- The StoreKit transaction listener starts as soon as `LifetimePurchaseStore` is created, so purchases approved outside the immediate purchase sheet are processed.

## Integration contract for the app target

1. Add this package locally to the Xcode project.
2. Bundle `content/puzzles-v2.json` with the app and decode it using `PuzzleCatalog.decode`.
3. Create one `ModelContainer` with `PersistenceContainer.make()` at app startup.
4. Create a `GamePersistenceStore` using `GamePersistenceStore.make(modelContainer:)`.
5. Open a puzzle through `PersistentGameSession.start(...)` and send every user action through `dispatch(...)`.
6. Use `KanjiCrosswordRootView(catalog:persistence:)`; it owns the default `LifetimePurchaseStore`.
7. Pause/resume on scene lifecycle changes so timer state does not count time spent outside active play.

The SwiftUI layer should never mutate `GameState` or SwiftData directly, and it should never manufacture an entitlement Boolean.

## Tests

```bash
swift test --package-path runtime
```

Linux CI validates the pure Swift domain and commerce contracts. macOS CI compiles StoreKit 2 and runs the SwiftData and commerce tests.
