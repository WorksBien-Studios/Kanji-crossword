import SwiftUI
import iOS18Shell
import KanjiCommerce
import KanjiGameCore
import KanjiPersistence

public struct KanjiCrosswordRootView: View {
    private let catalog: PuzzleCatalog
    private let persistence: GamePersistenceStore

    @StateObject private var purchaseStore: LifetimePurchaseStore
    @StateObject private var navigator = AppShellNavigator()
    @AppStorage("kanjiCrossword.tutorialCompleted") private var tutorialCompleted = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var purchasePromptPuzzle: Puzzle?

    @MainActor
    public init(
        catalog: PuzzleCatalog,
        persistence: GamePersistenceStore
    ) {
        self.catalog = catalog
        self.persistence = persistence
        self._purchaseStore = StateObject(
            wrappedValue: LifetimePurchaseStore()
        )
    }

    @MainActor
    public init(
        catalog: PuzzleCatalog,
        persistence: GamePersistenceStore,
        purchaseStore: LifetimePurchaseStore
    ) {
        self.catalog = catalog
        self.persistence = persistence
        self._purchaseStore = StateObject(wrappedValue: purchaseStore)
    }

    public var body: some View {
        AppShellView(
            tabIDs: ["play", "history", "settings"],
            navigator: navigator,
            initialSelection: "play"
        ) {
            Tab("遊ぶ", systemImage: "square.grid.3x3", value: "play") {
                PlayRootView(
                    catalog: catalog,
                    persistence: persistence,
                    purchaseStore: purchaseStore,
                    accessPolicy: accessPolicy,
                    onUnlockRequested: { puzzle in
                        purchasePromptPuzzle = puzzle
                    }
                )
            }
            .customizationID("kanji.tab.play")

            Tab("記録", systemImage: "calendar", value: "history") {
                HistoryRootView(persistence: persistence)
            }
            .customizationID("kanji.tab.history")

            Tab("設定", systemImage: "gearshape", value: "settings") {
                NavigationStack {
                    SettingsView(
                        persistence: persistence,
                        purchaseStore: purchaseStore
                    )
                }
            }
            .customizationID("kanji.tab.settings")
        }
        .tint(KanjiTheme.accent)
        .task {
            await purchaseStore.start()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await purchaseStore.refresh()
            }
        }
        .sheet(isPresented: Binding(
            get: { !tutorialCompleted },
            set: { if !$0 { tutorialCompleted = true } }
        )) {
            TutorialView {
                tutorialCompleted = true
            }
            .interactiveDismissDisabled()
        }
        .sheet(item: $purchasePromptPuzzle) { _ in
            LifetimeUnlockView(purchaseStore: purchaseStore)
        }
    }

    private var accessPolicy: PuzzleAccessPolicy {
        PuzzleAccessPolicy(
            catalog: catalog,
            hasLifetimeUnlock: purchaseStore.hasLifetimeUnlock
        )
    }
}
