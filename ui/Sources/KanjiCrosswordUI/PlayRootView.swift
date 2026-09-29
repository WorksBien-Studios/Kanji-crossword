import SwiftUI
import KanjiGameCore
import KanjiPersistence

public struct PlayRootView: View {
    private let catalog: PuzzleCatalog
    private let persistence: GamePersistenceStore
    private let accessPolicy: PuzzleAccessPolicy
    private let onUnlockRequested: (Puzzle) -> Void

    @State private var selectedPuzzleID: String?
    @State private var mode: PuzzleMode = .kanjiNankuro
    @State private var difficulty: PuzzleDifficulty = .easy
    @State private var recentProgress: SavedGame?

    public init(
        catalog: PuzzleCatalog,
        persistence: GamePersistenceStore,
        accessPolicy: PuzzleAccessPolicy,
        onUnlockRequested: @escaping (Puzzle) -> Void
    ) {
        self.catalog = catalog
        self.persistence = persistence
        self.accessPolicy = accessPolicy
        self.onUnlockRequested = onUnlockRequested
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedPuzzleID) {
                if let recentProgress {
                    Section("続きから") {
                        puzzleRow(recentProgress.puzzle, subtitle: "途中の問題")
                    }
                } else if let dailyPuzzle {
                    Section("今日の一問") {
                        puzzleRow(dailyPuzzle, subtitle: dailyPuzzle.difficulty.japaneseTitle)
                    }
                }

                Section {
                    Picker("モード", selection: $mode) {
                        ForEach(PuzzleMode.allCases, id: \.self) { mode in
                            Text(mode.japaneseTitle).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("難易度", selection: $difficulty) {
                        ForEach(PuzzleDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.japaneseTitle).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("問題") {
                    ForEach(filteredPuzzles) { puzzle in
                        puzzleRow(
                            puzzle,
                            subtitle: "\(puzzle.rows)×\(puzzle.columns)"
                        )
                    }
                }
            }
            .navigationTitle("遊ぶ")
        } detail: {
            if let selectedPuzzleID,
               let puzzle = catalog[selectedPuzzleID] ?? recentProgress?.puzzleIfMatching(selectedPuzzleID) {
                if accessPolicy.isUnlocked(puzzle) {
                    GameSessionContainerView(
                        puzzle: puzzle,
                        persistence: persistence
                    )
                    .id(puzzle.id)
                } else {
                    ContentUnavailableView {
                        Label("この問題は買い切り版です", systemImage: "lock")
                    } description: {
                        Text("無料の30問を遊んだあとも、全360問を広告なしで楽しめます。")
                    } actions: {
                        Button("買い切り版を見る") {
                            onUnlockRequested(puzzle)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ContentUnavailableView(
                    "問題を選んでください",
                    systemImage: "square.grid.3x3"
                )
            }
        }
        .task {
            recentProgress = try? await persistence.loadMostRecentProgress()
            if selectedPuzzleID == nil {
                selectedPuzzleID = recentProgress?.puzzle.id ?? dailyPuzzle?.id
            }
        }
    }

    @ViewBuilder
    private func puzzleRow(_ puzzle: Puzzle, subtitle: String) -> some View {
        if accessPolicy.isUnlocked(puzzle) {
            NavigationLink(value: puzzle.id) {
                PuzzleRowLabel(
                    puzzle: puzzle,
                    subtitle: subtitle,
                    locked: false
                )
            }
        } else {
            Button {
                onUnlockRequested(puzzle)
            } label: {
                PuzzleRowLabel(
                    puzzle: puzzle,
                    subtitle: subtitle,
                    locked: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var filteredPuzzles: [Puzzle] {
        catalog.puzzles(mode: mode, difficulty: difficulty)
    }

    private var dailyPuzzle: Puzzle? {
        guard !catalog.puzzles.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return catalog.puzzles[day % catalog.puzzles.count]
    }
}

private struct PuzzleRowLabel: View {
    let puzzle: Puzzle
    let subtitle: String
    let locked: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(puzzle.mode.japaneseTitle)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if locked {
                Image(systemName: "lock")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("買い切り版")
            }
        }
        .contentShape(Rectangle())
    }
}

private struct GameSessionContainerView: View {
    let puzzle: Puzzle
    let persistence: GamePersistenceStore

    @State private var model: GameSessionViewModel?
    @State private var loadError: String?

    var body: some View {
        Group {
            if let model {
                GameView(model: model)
            } else if let loadError {
                ContentUnavailableView {
                    Label("問題を開けません", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(loadError)
                }
            } else {
                ProgressView("問題を開いています")
            }
        }
        .task(id: puzzle.id) {
            do {
                let preferences = try await persistence.loadPreferences()
                model = try await GameSessionViewModel.make(
                    puzzle: puzzle,
                    timerEnabled: preferences.timerEnabledByDefault,
                    persistence: persistence
                )
                loadError = nil
            } catch {
                loadError = String(describing: error)
            }
        }
    }
}

private extension SavedGame {
    func puzzleIfMatching(_ id: String) -> Puzzle? {
        puzzle.id == id ? puzzle : nil
    }
}

extension PuzzleMode {
    var japaneseTitle: String {
        switch self {
        case .kanjiNankuro: "漢字ナンクロ"
        case .kanjiNankuroLarge: "大盤面"
        }
    }
}

extension PuzzleDifficulty {
    var japaneseTitle: String {
        switch self {
        case .easy: "やさしい"
        case .standard: "ふつう"
        case .hard: "むずかしい"
        case .expert: "達人"
        }
    }
}
