import SwiftUI
import iOS18Shell
import KanjiGameCore
import KanjiPersistence

public struct KanjiCrosswordRootView: View {
    private let catalog: PuzzleCatalog
    private let persistence: GamePersistenceStore
    private let accessPolicy: PuzzleAccessPolicy
    private let onUnlockRequested: (Puzzle) -> Void

    @StateObject private var navigator = AppShellNavigator()
    @AppStorage("kanjiCrossword.tutorialCompleted") private var tutorialCompleted = false

    public init(
        catalog: PuzzleCatalog,
        persistence: GamePersistenceStore,
        hasLifetimeUnlock: Bool,
        onUnlockRequested: @escaping (Puzzle) -> Void
    ) {
        self.catalog = catalog
        self.persistence = persistence
        self.accessPolicy = PuzzleAccessPolicy(
            catalog: catalog,
            hasLifetimeUnlock: hasLifetimeUnlock
        )
        self.onUnlockRequested = onUnlockRequested
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
                    accessPolicy: accessPolicy,
                    onUnlockRequested: onUnlockRequested
                )
            }
            .customizationID("kanji.tab.play")

            Tab("記録", systemImage: "calendar", value: "history") {
                HistoryRootView(persistence: persistence)
            }
            .customizationID("kanji.tab.history")

            Tab("設定", systemImage: "gearshape", value: "settings") {
                NavigationStack {
                    SettingsView(persistence: persistence)
                }
            }
            .customizationID("kanji.tab.settings")
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
    }
}
