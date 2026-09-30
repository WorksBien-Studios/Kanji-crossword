#if DEBUG
import SwiftUI
import KanjiCommerce
import KanjiGameCore
import KanjiPersistence

// Device previews of the real screens. Nothing here is a picture of the UI:
// every preview runs the shipping views against an in-memory store.
//
// Full app (real iOS 18 shell, tab bar, split view): pick the device in the
// canvas footer.
//   - "iPhone"                      -> iPhone 16
//   - "iPad 1カラム"                 -> iPad mini (A17 Pro), portrait   744 × 1133 pt
//   - "iPad 2カラム"                 -> iPad Pro 11-inch, landscape     1194 × 834 pt
//
// Play screen at an exact pane size: runs on any device.

// MARK: - Full app

#Preview("iPhone · 遊ぶ") {
    PreviewHost { catalog, persistence in
        KanjiCrosswordRootView(catalog: catalog, persistence: persistence)
    }
}

#Preview("iPad 1カラム · mini 縦", traits: .portrait) {
    PreviewHost { catalog, persistence in
        KanjiCrosswordRootView(catalog: catalog, persistence: persistence)
    }
}

#Preview("iPad 2カラム · 11インチ 横", traits: .landscapeLeft) {
    PreviewHost { catalog, persistence in
        KanjiCrosswordRootView(catalog: catalog, persistence: persistence)
    }
}

// MARK: - Play screen at exact pane sizes

#Preview("盤面 · iPhone 393pt", traits: .fixedLayout(width: 393, height: 760)) {
    PreviewHost { _, persistence in
        PlayScreenPreview(persistence: persistence)
    }
}

#Preview("盤面 · iPad 1カラム 744pt", traits: .fixedLayout(width: 744, height: 960)) {
    PreviewHost { _, persistence in
        PlayScreenPreview(persistence: persistence)
    }
}

#Preview("盤面 · iPad 2カラム 854pt", traits: .fixedLayout(width: 854, height: 710)) {
    PreviewHost { _, persistence in
        PlayScreenPreview(persistence: persistence)
    }
}

// MARK: - Harness

private struct PreviewHost<Content: View>: View {
    let content: (PuzzleCatalog, GamePersistenceStore) -> Content
    @State private var seed: PreviewSeed?

    init(@ViewBuilder content: @escaping (PuzzleCatalog, GamePersistenceStore) -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            if let seed {
                content(seed.catalog, seed.persistence)
            } else {
                ProgressView()
            }
        }
        .task {
            seed = await PreviewSeed.make()
        }
    }
}

struct PlayScreenPreview: View {
    let persistence: GamePersistenceStore

    @StateObject private var purchaseStore: LifetimePurchaseStore
    @State private var model: GameSessionViewModel?

    @MainActor
    init(persistence: GamePersistenceStore) {
        self.persistence = persistence
        self._purchaseStore = StateObject(wrappedValue: LifetimePurchaseStore())
    }

    var body: some View {
        NavigationStack {
            if let model {
                GameView(
                    model: model,
                    persistence: persistence,
                    purchaseStore: purchaseStore
                )
            } else {
                ProgressView()
            }
        }
        .task {
            model = try? await GameSessionViewModel.make(
                puzzle: PreviewFixtures.puzzle(number: PreviewFixtures.resumeNumber),
                preferences: AppPreferences(),
                persistence: persistence
            )
        }
    }
}

/// A catalog of twelve 大盤面 puzzles and a store holding one in-progress game
/// (ten squares filled, number 1 selected), so the list shows its 続きから card.
@MainActor
struct PreviewSeed {
    let catalog: PuzzleCatalog
    let persistence: GamePersistenceStore

    static func make() async -> PreviewSeed? {
        UserDefaults.standard.set(true, forKey: "kanjiCrossword.tutorialCompleted")
        guard let container = try? PersistenceContainer.make(inMemory: true),
              let catalog = try? PuzzleCatalog(
                puzzles: (1...12).map { PreviewFixtures.puzzle(number: $0) },
                enforceLaunchLibrary: false
              ) else { return nil }

        let persistence = GamePersistenceStore.make(modelContainer: container)
        let puzzle = PreviewFixtures.puzzle(number: PreviewFixtures.resumeNumber)
        if let session = try? await PersistentGameSession.start(
            puzzle: puzzle,
            timerEnabled: false,
            persistence: persistence
        ) {
            for number in [2, 3, 4, 8, 9, 12, 13, 14, 15] {
                _ = try? await session.dispatch(.selectNumber(number))
                _ = try? await session.dispatch(
                    .enterKanji(puzzle.solutionByNumber[number] ?? "")
                )
            }
            _ = try? await session.dispatch(.selectNumber(1))
        }
        return PreviewSeed(catalog: catalog, persistence: persistence)
    }
}

/// A 9 × 8 大盤面 board with 22 crossing words and 23 distinct kanji. Numbers
/// are assigned in reading order and word spans are found by scanning runs, so
/// the fixture cannot drift out of sync with its own layout.
enum PreviewFixtures {
    static let resumeNumber = 3

    private static let blank: Character = "・"

    private static let grid: [[Character]] = [
        "日本・・天・・・・",
        "曜・・・気・・・・",
        "日光・・予・・・・",
        "・線路・報道・・・",
        "・・上空・路面・・",
        "・・・港町・積極・",
        "・・・・名前・限度",
        "・・・・・日曜・胸"
    ].map { Array($0) }

    private static let readings: [String: String] = [
        "日本": "にほん", "日曜日": "にちようび", "日光": "にっこう", "光線": "こうせん",
        "線路": "せんろ", "路上": "ろじょう", "上空": "じょうくう", "空港": "くうこう",
        "港町": "みなとまち", "町名": "ちょうめい", "名前": "なまえ", "前日": "ぜんじつ",
        "日曜": "にちよう", "天気予報": "てんきよほう", "報道": "ほうどう", "道路": "どうろ",
        "路面": "ろめん", "面積": "めんせき", "積極": "せっきょく", "極限": "きょくげん",
        "限度": "げんど", "度胸": "どきょう"
    ]

    private static let tray = Array("路予名日極本光胸前天積道気限線報上町度空曜港面").map(String.init)

    static func puzzle(number index: Int) -> Puzzle {
        let rows = grid.count
        let columns = grid[0].count

        var numberByKanji: [Character: Int] = [:]
        var cellNumbers: [String: Int] = [:]
        var layout = Array(
            repeating: Array(repeating: "#", count: columns),
            count: rows
        )
        for row in 0..<rows {
            for column in 0..<columns where grid[row][column] != blank {
                let kanji = grid[row][column]
                let number = numberByKanji[kanji, default: numberByKanji.count + 1]
                numberByKanji[kanji] = number
                cellNumbers["\(row),\(column)"] = number
                layout[row][column] = "."
            }
        }

        var spans: [WordSpan] = []
        func scan(_ lines: [[(Int, Int)]]) {
            for line in lines {
                var run: [(Int, Int)] = []
                for cell in line + [(-1, -1)] {
                    if cell.0 >= 0, grid[cell.0][cell.1] != blank {
                        run.append(cell)
                        continue
                    }
                    if run.count >= 2 {
                        let word = String(run.map { grid[$0.0][$0.1] })
                        spans.append(
                            WordSpan(
                                word: word,
                                reading: readings[word] ?? word,
                                cells: run.map { "\($0.0),\($0.1)" }
                            )
                        )
                    }
                    run = []
                }
            }
        }
        scan((0..<rows).map { row in (0..<columns).map { (row, $0) } })
        scan((0..<columns).map { column in (0..<rows).map { ($0, column) } })

        let solution = Dictionary(
            uniqueKeysWithValues: numberByKanji.map { (String($0.value), String($0.key)) }
        )
        let starterNumber = numberByKanji["気"] ?? 0

        return Puzzle(
            schemaVersion: 2,
            mode: .kanjiNankuroLarge,
            difficulty: .hard,
            difficultyScore: 0.7,
            difficultyMetrics: DifficultyMetrics(
                clueScarcity: 0.9,
                maxLogicDepth: 4,
                averageLogicDepth: 2,
                branchingBits: 3
            ),
            rows: rows,
            columns: columns,
            cellLayout: layout,
            cellNumbers: cellNumbers,
            solution: solution,
            starterCells: [String(starterNumber): "気"],
            wordSpans: spans,
            editorialStatus: "preview",
            editorialNotes: "",
            sourceNotes: "",
            id: "nankuro-v2-preview-\(index)",
            traySeed: tray,
            validationDigest: String(repeating: "0", count: 64)
        )
    }
}
#endif
