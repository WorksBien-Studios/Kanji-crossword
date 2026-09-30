import SwiftUI
import KanjiCrosswordUI

@main
struct KanjiCrosswordApp: App {
    private let launch = LaunchResult.load()

    var body: some Scene {
        WindowGroup {
            switch launch {
            case .ready(let catalog, let persistence):
                KanjiCrosswordRootView(catalog: catalog, persistence: persistence)
            case .failed(let message):
                ContentUnavailableView(
                    "起動できませんでした",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
    }
}

private enum LaunchResult {
    case ready(PuzzleCatalog, GamePersistenceStore)
    case failed(String)

    static func load() -> LaunchResult {
        do {
            guard let url = Bundle.main.url(forResource: "puzzles-v2", withExtension: "json") else {
                return .failed("問題データが見つかりません。アプリを再インストールしてください。")
            }
            let catalog = try PuzzleCatalog.decode(Data(contentsOf: url))
            let container = try PersistenceContainer.make()
            return .ready(catalog, GamePersistenceStore.make(modelContainer: container))
        } catch {
            return .failed(String(describing: error))
        }
    }
}
