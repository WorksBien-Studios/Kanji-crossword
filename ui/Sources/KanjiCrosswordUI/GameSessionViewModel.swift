import Foundation
import SwiftUI
import KanjiGameCore
import KanjiPersistence

@MainActor
public final class GameSessionViewModel: ObservableObject {
    @Published public private(set) var state: GameState
    @Published public private(set) var lastEvent: GameEvent = .none
    @Published public private(set) var errorMessage: String?

    public let puzzle: Puzzle
    public let preferences: AppPreferences

    private let session: PersistentGameSession

    private init(
        state: GameState,
        puzzle: Puzzle,
        preferences: AppPreferences,
        session: PersistentGameSession
    ) {
        self.state = state
        self.puzzle = puzzle
        self.preferences = preferences
        self.session = session
    }

    public static func make(
        puzzle: Puzzle,
        preferences: AppPreferences,
        persistence: GamePersistenceStore
    ) async throws -> GameSessionViewModel {
        let session = try await PersistentGameSession.start(
            puzzle: puzzle,
            timerEnabled: preferences.timerEnabledByDefault,
            persistence: persistence
        )
        let state = await session.state
        let savedPuzzle = await session.puzzle
        return GameSessionViewModel(
            state: state,
            puzzle: savedPuzzle,
            preferences: preferences,
            session: session
        )
    }

    public func send(_ action: GameAction, now: Date = Date()) {
        Task {
            do {
                let transition = try await session.dispatch(action, now: now)
                state = transition.state
                lastEvent = transition.event
                errorMessage = nil
            } catch {
                errorMessage = String(describing: error)
            }
        }
    }

    public func clearTransientEvent() {
        lastEvent = .none
    }

    public func clearError() {
        errorMessage = nil
    }
}
