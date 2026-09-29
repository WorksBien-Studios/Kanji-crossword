import SwiftUI
import iOS18Shell
import KanjiGameCore
import KanjiPersistence

public struct KanjiCrosswordRootView: View {
    private let catalog: PuzzleCatalog
    private let persistence: GamePersistenceStore

    @StateObject private var navigator = AppShellNavigator()
    @AppStorage("kanjiCrossword.tutorialCompleted") private var tutorialCompleted = false

    public init(catalog: PuzzleCatalog, persistence: GamePersistenceStore) {
        self.catalog = catalog
        self.persistence = persistence
    }

    public var body: some View {
        AppShellView(
            tabIDs: ["play", "history", "settings"],
            navigator: navigator,
            initialSelection: "play"
        ) {
            Tab("遊ぶ", systemImage: "square.grid.3x3", value: "play") {
                PlayRootView(catalog: catalog, persistence: persistence)
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
