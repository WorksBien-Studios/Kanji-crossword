#if canImport(SwiftData)
import Foundation
import SwiftData
import Testing
import KanjiGameCore
@testable import KanjiPersistence

@Suite("SwiftData persistence")
struct PersistenceTests {
    @Test("active progress round-trips with immutable puzzle snapshot")
    func activeRoundTrip() async throws {
        let puzzle = persistencePuzzle()
        let container = try PersistenceContainer.make(inMemory: true)
        let store = GamePersistenceStore.make(modelContainer: container)
        var state = GameState(puzzle: puzzle, timerEnabled: false)

        state = try GameReducer.reduce(
            state: state,
            action: .selectNumber(2),
            puzzle: puzzle
        ).state
        state = try GameReducer.reduce(
            state: state,
            action: .enterKanji("本"),
            puzzle: puzzle
        ).state
        state = try GameReducer.reduce(
            state: state,
            action: .updateViewport(
                BoardViewport(zoomScale: 2.5, centerRow: 1, centerColumn: 1)
            ),
            puzzle: puzzle
        ).state

        try await store.save(state: state, puzzle: puzzle)
        let loaded = try await store.loadProgress(puzzleID: puzzle.id)
        #expect(loaded?.state == state)
        #expect(loaded?.puzzle == puzzle)
    }

    @Test("completion is archived and active progress is removed in one save")
    func completionArchive() async throws {
        let puzzle = persistencePuzzle()
        let container = try PersistenceContainer.make(inMemory: true)
        let store = GamePersistenceStore.make(modelContainer: container)
        var state = GameState(puzzle: puzzle, timerEnabled: false)
        try await store.save(state: state, puzzle: puzzle)

        state = try GameReducer.reduce(
            state: state,
            action: .selectNumber(2),
            puzzle: puzzle
        ).state
        state = try GameReducer.reduce(
            state: state,
            action: .enterKanji("本"),
            puzzle: puzzle
        ).state
        state = try GameReducer.reduce(
            state: state,
            action: .selectNumber(3),
            puzzle: puzzle
        ).state
        state = try GameReducer.reduce(
            state: state,
            action: .enterKanji("語"),
            puzzle: puzzle
        ).state
        #expect(state.status == .completed)

        try await store.save(state: state, puzzle: puzzle)

        #expect(try await store.loadProgress(puzzleID: puzzle.id) == nil)
        let history = try await store.completionHistory()
        #expect(history.count == 1)
        #expect(history.first?.state == state)
        #expect(history.first?.puzzle == puzzle)
    }

    @Test("preferences round-trip through the singleton record")
    func preferences() async throws {
        let container = try PersistenceContainer.make(inMemory: true)
        let store = GamePersistenceStore.make(modelContainer: container)
        let expected = AppPreferences(
            textScale: 1.4,
            highContrast: true,
            hapticsEnabled: true,
            timerEnabledByDefault: true
        )
        try await store.savePreferences(expected)
        #expect(try await store.loadPreferences() == expected)
    }
}

private func persistencePuzzle() -> Puzzle {
    Puzzle(
        schemaVersion: 2,
        mode: .kanjiNankuro,
        difficulty: .standard,
        difficultyScore: 0.5,
        difficultyMetrics: DifficultyMetrics(
            clueScarcity: 0.5,
            maxLogicDepth: 3,
            averageLogicDepth: 1.5,
            branchingBits: 0.25
        ),
        rows: 2,
        columns: 2,
        cellLayout: [[".", "."], [".", "."]],
        cellNumbers: ["0,0": 1, "0,1": 2, "1,0": 1, "1,1": 3],
        solution: ["1": "日", "2": "本", "3": "語"],
        starterCells: ["1": "日"],
        wordSpans: [
            WordSpan(word: "日本", reading: "にほん", cells: ["0,0", "0,1"]),
            WordSpan(word: "日語", reading: "にちご", cells: ["1,0", "1,1"])
        ],
        editorialStatus: "ai_review_passed_owner_approved",
        editorialNotes: "test",
        sourceNotes: "test",
        id: "nankuro-v2-fedcba9876543210abcd",
        traySeed: ["語", "日", "本"],
        validationDigest: String(repeating: "b", count: 64)
    )
}
#endif
