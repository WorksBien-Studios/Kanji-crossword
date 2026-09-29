import SwiftUI
import KanjiPersistence

public struct HistoryRootView: View {
    let persistence: GamePersistenceStore

    @State private var history: [CompletedGame] = []
    @State private var selectedSessionID: UUID?
    @State private var loadError: String?

    public init(persistence: GamePersistenceStore) {
        self.persistence = persistence
    }

    public var body: some View {
        NavigationSplitView {
            Group {
                if history.isEmpty, loadError == nil {
                    ContentUnavailableView(
                        "まだ記録がありません",
                        systemImage: "calendar"
                    )
                } else {
                    List(history, selection: $selectedSessionID) { game in
                        NavigationLink(value: game.id) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(game.puzzle.mode.japaneseTitle)
                                if let completedAt = game.state.completedAt {
                                    Text(completedAt, format: .dateTime.year().month().day())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("記録")
        } detail: {
            if let game = selectedGame {
                ResultsView(state: game.state, puzzle: game.puzzle)
            } else if let loadError {
                ContentUnavailableView {
                    Label("記録を読み込めません", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(loadError)
                }
            } else {
                ContentUnavailableView(
                    "記録を選んでください",
                    systemImage: "checkmark.circle"
                )
            }
        }
        .task {
            await reload()
        }
    }

    private var selectedGame: CompletedGame? {
        guard let selectedSessionID else { return nil }
        return history.first { $0.id == selectedSessionID }
    }

    @MainActor
    private func reload() async {
        do {
            history = try await persistence.completionHistory()
            if selectedSessionID == nil {
                selectedSessionID = history.first?.id
            }
            loadError = nil
        } catch {
            loadError = String(describing: error)
        }
    }
}
