#if canImport(SwiftData)
import Foundation
import KanjiGameCore

public actor PersistentGameSession {
    public private(set) var state: GameState
    public let puzzle: Puzzle
    private let persistence: GamePersistenceStore

    public init(
        state: GameState,
        puzzle: Puzzle,
        persistence: GamePersistenceStore
    ) throws {
        guard state.puzzleID == puzzle.id else { throw PersistenceError.statePuzzleMismatch }
        self.state = state
        self.puzzle = puzzle
        self.persistence = persistence
    }

    public static func start(
        puzzle: Puzzle,
        timerEnabled: Bool,
        persistence: GamePersistenceStore,
        now: Date = Date()
    ) async throws -> PersistentGameSession {
        if let saved = try await persistence.loadProgress(puzzleID: puzzle.id) {
            return try PersistentGameSession(
                state: saved.state,
                puzzle: saved.puzzle,
                persistence: persistence
            )
        }
        let state = GameState(puzzle: puzzle, timerEnabled: timerEnabled, now: now)
        try await persistence.save(state: state, puzzle: puzzle, now: now)
        return try PersistentGameSession(
            state: state,
            puzzle: puzzle,
            persistence: persistence
        )
    }

    @discardableResult
    public func dispatch(
        _ action: GameAction,
        now: Date = Date()
    ) async throws -> GameTransition {
        let transition = try GameReducer.reduce(
            state: state,
            action: action,
            puzzle: puzzle,
            now: now
        )
        if transition.didChangeState {
            try await persistence.save(
                state: transition.state,
                puzzle: puzzle,
                now: now
            )
        }
        state = transition.state
        return transition
    }
}
#endif
