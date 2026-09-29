import Foundation
import Testing
@testable import KanjiGameCore

@Suite("Game reducer")
struct GameReducerTests {
    @Test("starter cells are immutable and wrong input never destroys other progress")
    func starterAndIsolation() throws {
        let puzzle = samplePuzzle()
        var state = GameState(puzzle: puzzle, timerEnabled: false)
        state = try GameReducer.reduce(
            state: state,
            action: .selectNumber(1),
            puzzle: puzzle
        ).state
        let ignored = try GameReducer.reduce(
            state: state,
            action: .enterKanji("本"),
            puzzle: puzzle
        )
        #expect(ignored.state.entries[1] == "日")
        #expect(!ignored.didChangeState)

        state = try GameReducer.reduce(
            state: state,
            action: .selectNumber(2),
            puzzle: puzzle
        ).state
        state = try GameReducer.reduce(
            state: state,
            action: .enterKanji("語"),
            puzzle: puzzle
        ).state
        #expect(state.entries[1] == "日")
        #expect(state.entries[2] == "語")
    }

    @Test("undo and redo are deterministic")
    func undoRedo() throws {
        let puzzle = samplePuzzle()
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
        #expect(state.entries[2] == "本")

        state = try GameReducer.reduce(
            state: state,
            action: .undo,
            puzzle: puzzle
        ).state
        #expect(state.entries[2] == nil)

        state = try GameReducer.reduce(
            state: state,
            action: .redo,
            puzzle: puzzle
        ).state
        #expect(state.entries[2] == "本")
    }

    @Test("mistake check reports but never corrects")
    func checkMistakes() throws {
        let puzzle = samplePuzzle()
        var state = GameState(puzzle: puzzle, timerEnabled: false)
        state = try GameReducer.reduce(
            state: state,
            action: .selectNumber(2),
            puzzle: puzzle
        ).state
        state = try GameReducer.reduce(
            state: state,
            action: .enterKanji("語"),
            puzzle: puzzle
        ).state
        let transition = try GameReducer.reduce(
            state: state,
            action: .checkMistakes,
            puzzle: puzzle
        )
        #expect(transition.event == .mistakes([2]))
        #expect(transition.state.entries[2] == "語")
        #expect(transition.state.checksUsed == 1)
    }

    @Test("hint is counted and undo only undoes the placement")
    func hintAccounting() throws {
        let puzzle = samplePuzzle()
        let state = GameState(puzzle: puzzle, timerEnabled: false)
        let hinted = try GameReducer.reduce(
            state: state,
            action: .requestHint,
            puzzle: puzzle
        )
        #expect(hinted.state.hintsUsed == 1)
        guard case .hint(let explanation) = hinted.event else {
            Issue.record("Expected hint event")
            return
        }
        #expect(hinted.state.entries[explanation.number] == explanation.kanji)

        let undone = try GameReducer.reduce(
            state: hinted.state,
            action: .undo,
            puzzle: puzzle
        )
        #expect(undone.state.entries[explanation.number] == nil)
        #expect(undone.state.hintsUsed == 1)
    }

    @Test("completion freezes gameplay and captures timer")
    func completion() throws {
        let puzzle = samplePuzzle()
        let start = Date(timeIntervalSince1970: 100)
        var state = GameState(puzzle: puzzle, timerEnabled: true, now: start)
        state = try GameReducer.reduce(
            state: state,
            action: .selectNumber(2),
            puzzle: puzzle,
            now: start
        ).state
        state = try GameReducer.reduce(
            state: state,
            action: .enterKanji("本"),
            puzzle: puzzle,
            now: start
        ).state
        state = try GameReducer.reduce(
            state: state,
            action: .selectNumber(3),
            puzzle: puzzle,
            now: start
        ).state
        let final = try GameReducer.reduce(
            state: state,
            action: .enterKanji("語"),
            puzzle: puzzle,
            now: Date(timeIntervalSince1970: 130)
        )
        #expect(final.event == .completed)
        #expect(final.state.status == .completed)
        #expect(final.state.completedAt == Date(timeIntervalSince1970: 130))
        #expect(final.state.elapsedBeforeCurrentRun == 30)
        #expect(final.state.timerRunningSince == nil)

        let ignored = try GameReducer.reduce(
            state: final.state,
            action: .eraseSelected,
            puzzle: puzzle
        )
        #expect(!ignored.didChangeState)
    }

    @Test("viewport is normalized and survives Codable round trip")
    func viewportRoundTrip() throws {
        let puzzle = samplePuzzle()
        let state = GameState(puzzle: puzzle, timerEnabled: false)
        let transition = try GameReducer.reduce(
            state: state,
            action: .updateViewport(
                BoardViewport(zoomScale: 9, centerRow: 99, centerColumn: -2)
            ),
            puzzle: puzzle
        )
        #expect(transition.state.viewport.zoomScale == 4)
        #expect(transition.state.viewport.centerRow == 1)
        #expect(transition.state.viewport.centerColumn == 0)

        let encoded = try JSONEncoder().encode(transition.state)
        let decoded = try JSONDecoder().decode(GameState.self, from: encoded)
        #expect(decoded == transition.state)
    }

    @Test("restart requires explicit confirmed action and preserves session identity")
    func restart() throws {
        let puzzle = samplePuzzle()
        var state = GameState(puzzle: puzzle, timerEnabled: false)
        let originalSession = state.sessionID
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
        let restarted = try GameReducer.reduce(
            state: state,
            action: .restartConfirmed,
            puzzle: puzzle
        )
        #expect(restarted.state.sessionID == originalSession)
        #expect(restarted.state.entries == puzzle.startersByNumber)
        #expect(restarted.state.undoStack.isEmpty)
    }
}
