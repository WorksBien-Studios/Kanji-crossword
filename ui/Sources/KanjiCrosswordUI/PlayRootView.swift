import SwiftUI
import KanjiCommerce
import KanjiGameCore
import KanjiPersistence

public struct PlayRootView: View {
    private let catalog: PuzzleCatalog
    private let persistence: GamePersistenceStore
    private let purchaseStore: LifetimePurchaseStore
    private let accessPolicy: PuzzleAccessPolicy
    private let onUnlockRequested: (Puzzle) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedPuzzleID: String?
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    @State private var mode: PuzzleMode = .kanjiNankuro
    @State private var difficulty: PuzzleDifficulty = .easy
    @State private var recentProgress: SavedGame?
    @State private var completedIDs: Set<String> = []
    @State private var completionDates: [Date] = []
    @State private var showTutorial = false
    @State private var paneWidth: CGFloat = 0
    @State private var oneColumnDetailShown = false

    /// A regular-width iPad narrower than 800pt (iPad mini upright) shows the
    /// puzzle list and the board as two full-width steps. Wider panes get the
    /// split view, where the list stays in a 340pt sidebar.
    private var usesOneColumn: Bool {
        horizontalSizeClass == .regular
            && paneWidth > 0
            && paneWidth < PlayLayout.oneColumnMaxWidth
    }

    public init(
        catalog: PuzzleCatalog,
        persistence: GamePersistenceStore,
        purchaseStore: LifetimePurchaseStore,
        accessPolicy: PuzzleAccessPolicy,
        onUnlockRequested: @escaping (Puzzle) -> Void
    ) {
        self.catalog = catalog
        self.persistence = persistence
        self.purchaseStore = purchaseStore
        self.accessPolicy = accessPolicy
        self.onUnlockRequested = onUnlockRequested
    }

    public var body: some View {
        Group {
            if usesOneColumn {
                oneColumn
            } else {
                splitView
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            paneWidth = width
        }
        .task {
            await reload()
            if selectedPuzzleID == nil, horizontalSizeClass == .regular {
                selectedPuzzleID = recentProgress?.puzzle.id ?? dailyPuzzle?.id
            }
        }
        .onChange(of: selectedPuzzleID) { _, _ in
            Task {
                await reload()
            }
        }
        .sheet(isPresented: $showTutorial) {
            TutorialView {
                showTutorial = false
            }
        }
    }

    // MARK: Containers

    private var splitView: some View {
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            listPane
                .navigationSplitViewColumnWidth(min: 320, ideal: 340, max: 380)
        } detail: {
            detail
        }
    }

    private var oneColumn: some View {
        NavigationStack {
            listPane
                .navigationDestination(isPresented: $oneColumnDetailShown) {
                    detail
                }
        }
    }

    private var listPane: some View {
        sidebar
            .navigationTitle("遊ぶ")
            .background(KanjiTheme.canvas)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("遊び方") {
                        showTutorial = true
                    }
                    .fontWeight(.bold)
                }
            }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(JapaneseDateText.eraDate(Date()))
                    .font(.subheadline)
                    .foregroundStyle(KanjiTheme.inkSecondary)

                if let recentProgress {
                    resumeCard(recentProgress)
                }
                if let dailyPuzzle {
                    dailyCard(dailyPuzzle)
                }

                Text("問題を選ぶ")
                    .font(.subheadline.bold())
                    .foregroundStyle(KanjiTheme.inkSecondary)
                    .padding(.top, 4)

                HStack(spacing: 12) {
                    ForEach(PuzzleMode.allCases, id: \.self) { candidate in
                        modeTile(candidate)
                    }
                }

                Picker("難易度", selection: $difficulty) {
                    ForEach(PuzzleDifficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.japaneseTitle).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)

                Text("難しさは、ヒントの少なさと推理の深さで決まります。盤の大きさは、各問題に別に表示されます。")
                    .font(.footnote)
                    .foregroundStyle(KanjiTheme.inkSecondary)

                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: usesOneColumn ? 84 : 76), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(Array(filteredPuzzles.enumerated()), id: \.element.id) { index, puzzle in
                        puzzleTile(puzzle, number: index + 1)
                    }
                }

                if !purchaseStore.hasLifetimeUnlock {
                    Text("鍵のついた問題は買い切り版です。無料の問題は、これからもずっと広告なしで遊べます。")
                        .font(.footnote)
                        .foregroundStyle(KanjiTheme.inkSecondary)
                }

                progressCard
            }
            .padding(16)
            .frame(
                maxWidth: usesOneColumn
                    ? PlayLayout.readableListWidth + 32
                    : .infinity
            )
            .frame(maxWidth: .infinity)
        }
    }

    private func resumeCard(_ saved: SavedGame) -> some View {
        Button {
            select(saved.puzzle)
        } label: {
            KanjiCard {
                HStack(spacing: 14) {
                    MiniBoardView(
                        puzzle: saved.puzzle,
                        cellSize: saved.puzzle.columns > 10 ? 7 : 11,
                        style: .progress(saved.state.entries)
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("続きから")
                            .font(.subheadline)
                            .foregroundStyle(KanjiTheme.inkSecondary)
                        Text("\(saved.puzzle.difficulty.japaneseTitle) ・ \(saved.puzzle.mode.japaneseTitle)")
                            .font(.title3.bold())
                            .foregroundStyle(KanjiTheme.ink)
                        Text("\(saved.puzzle.solution.count)マス中 \(saved.state.entries.count)マス入力済み")
                            .font(.subheadline)
                            .foregroundStyle(KanjiTheme.inkSecondary)
                    }
                    Spacer(minLength: 0)
                }
                Text("続きを遊ぶ")
                    .font(.title3.bold())
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(KanjiTheme.accent)
                    )
                    .padding(.top, 8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("続きから遊ぶ")
    }

    private func dailyCard(_ puzzle: Puzzle) -> some View {
        KanjiCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今日の一問")
                        .font(.subheadline)
                        .foregroundStyle(KanjiTheme.inkSecondary)
                    Text("\(puzzle.difficulty.japaneseTitle) ・ \(puzzle.rows)×\(puzzle.columns)")
                        .font(.headline)
                        .foregroundStyle(KanjiTheme.ink)
                }
                Spacer()
                Button(accessPolicy.isUnlocked(puzzle) ? "はじめる" : "鍵つき") {
                    select(puzzle)
                }
                .buttonStyle(KanjiSecondaryButtonStyle(compact: true))
                .frame(width: 128)
            }
        }
    }

    private func modeTile(_ candidate: PuzzleMode) -> some View {
        let count = catalog.puzzles.filter { $0.mode == candidate }.count
        let done = catalog.puzzles.filter {
            $0.mode == candidate && completedIDs.contains($0.id)
        }.count
        return Button {
            mode = candidate
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.japaneseTitle)
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .foregroundStyle(KanjiTheme.ink)
                Text(candidate == .kanjiNankuro ? "12〜18語 ・ 定番" : "20〜24語 ・ 拡大可")
                    .font(.footnote)
                    .foregroundStyle(KanjiTheme.inkSecondary)
                Text("完成 \(done)問 / \(count)問")
                    .font(.footnote)
                    .foregroundStyle(KanjiTheme.inkSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(KanjiTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        mode == candidate ? KanjiTheme.accent : KanjiTheme.line,
                        lineWidth: mode == candidate ? 3 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(mode == candidate ? [.isSelected] : [])
    }

    private func puzzleTile(_ puzzle: Puzzle, number: Int) -> some View {
        let locked = !accessPolicy.isUnlocked(puzzle)
        let done = completedIDs.contains(puzzle.id)
        let inProgress = recentProgress?.puzzle.id == puzzle.id
        let isSelected = selectedPuzzleID == puzzle.id
        return Button {
            select(puzzle)
        } label: {
            VStack(spacing: 4) {
                if locked {
                    Image(systemName: "lock")
                        .foregroundStyle(KanjiTheme.inkSecondary)
                }
                Text(String(number))
                    .font(.headline)
                    .foregroundStyle(locked ? KanjiTheme.inkSecondary : KanjiTheme.ink)
                if done {
                    StampMark(kind: .complete, size: 24)
                } else if inProgress {
                    Text("途中")
                        .font(.footnote)
                        .foregroundStyle(KanjiTheme.accentText)
                } else if !locked {
                    Text("まだ")
                        .font(.footnote)
                        .foregroundStyle(KanjiTheme.inkSecondary)
                }
                Text("\(puzzle.rows)×\(puzzle.columns)")
                    .font(.caption2)
                    .foregroundStyle(KanjiTheme.inkSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(locked ? KanjiTheme.fill : KanjiTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected || inProgress ? KanjiTheme.accent : KanjiTheme.line,
                        lineWidth: isSelected || inProgress ? 3 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "第\(number)問、\(locked ? "買い切り版" : done ? "完成" : inProgress ? "途中" : "未完成")"
        )
    }

    /// A quiet count of days played and puzzles finished. No streak.
    private var progressCard: some View {
        let days = PlayStats.playedDays(
            completionDates,
            inMonthOf: Date(),
            calendar: .current
        ).count
        return KanjiCard {
            HStack(spacing: 14) {
                StampMark(kind: .complete, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text("今月 \(days)日 遊びました")
                        .font(.headline)
                        .foregroundStyle(KanjiTheme.ink)
                    Text("完成 \(completedIDs.count)問 ・ 記録で振り返れます")
                        .font(.subheadline)
                        .foregroundStyle(KanjiTheme.inkSecondary)
                }
            }
        }
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        if let selectedPuzzleID,
           let puzzle = catalog[selectedPuzzleID] ?? recentProgress?.puzzleIfMatching(selectedPuzzleID) {
            if accessPolicy.isUnlocked(puzzle) {
                GameSessionContainerView(
                    puzzle: puzzle,
                    persistence: persistence,
                    purchaseStore: purchaseStore,
                    onBackToList: {
                        compactColumn = .sidebar
                        oneColumnDetailShown = false
                    },
                    onNextPuzzle: nextPuzzleAction(after: puzzle)
                )
                .id(puzzle.id)
            } else {
                ContentUnavailableView {
                    Label("この問題は買い切り版です", systemImage: "lock")
                } description: {
                    Text("無料の30問を遊んだあとも、全360問を広告なしで楽しめます。")
                } actions: {
                    Button(unlockButtonTitle) {
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

    // MARK: Actions

    /// Offers the next unfinished, unlocked puzzle in the same mode and
    /// difficulty. Returns nil when there is none, so the button is hidden.
    private func nextPuzzleAction(after puzzle: Puzzle) -> (() -> Void)? {
        let list = catalog.puzzles(mode: puzzle.mode, difficulty: puzzle.difficulty)
        guard let next = PuzzleSequence.next(
            after: puzzle.id,
            in: list,
            where: { accessPolicy.isUnlocked($0) && !completedIDs.contains($0.id) }
        ) else { return nil }
        return {
            selectedPuzzleID = next.id
            compactColumn = .detail
            oneColumnDetailShown = true
        }
    }

    private func select(_ puzzle: Puzzle) {
        if accessPolicy.isUnlocked(puzzle) {
            selectedPuzzleID = puzzle.id
            compactColumn = .detail
            oneColumnDetailShown = true
        } else {
            onUnlockRequested(puzzle)
        }
    }

    @MainActor
    private func reload() async {
        recentProgress = try? await persistence.loadMostRecentProgress()
        let history = (try? await persistence.completionHistory()) ?? []
        completedIDs = Set(history.map { $0.puzzle.id })
        completionDates = history.compactMap { $0.state.completedAt }
    }

    private var filteredPuzzles: [Puzzle] {
        catalog.puzzles(mode: mode, difficulty: difficulty)
    }

    private var dailyPuzzle: Puzzle? {
        guard !catalog.puzzles.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return catalog.puzzles[day % catalog.puzzles.count]
    }

    private var unlockButtonTitle: String {
        if let price = purchaseStore.localizedPrice {
            return "買い切り版を見る（\(price)）"
        }
        return "買い切り版を見る"
    }
}

private struct GameSessionContainerView: View {
    let puzzle: Puzzle
    let persistence: GamePersistenceStore
    let purchaseStore: LifetimePurchaseStore
    let onBackToList: () -> Void
    let onNextPuzzle: (() -> Void)?

    @State private var model: GameSessionViewModel?
    @State private var loadError: String?

    var body: some View {
        Group {
            if let model {
                GameView(
                    model: model,
                    persistence: persistence,
                    purchaseStore: purchaseStore,
                    onBackToList: onBackToList,
                    onNextPuzzle: onNextPuzzle
                )
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
                    preferences: preferences,
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
