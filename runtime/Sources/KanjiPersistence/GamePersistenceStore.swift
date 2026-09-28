#if canImport(SwiftData)
import Foundation
import SwiftData
import KanjiGameCore

public struct SavedGame: Sendable {
    public let state: GameState
    public let puzzle: Puzzle
    public let updatedAt: Date

    public init(state: GameState, puzzle: Puzzle, updatedAt: Date) {
        self.state = state
        self.puzzle = puzzle
        self.updatedAt = updatedAt
    }
}

public struct CompletedGame: Sendable, Identifiable {
    public var id: UUID { state.sessionID }
    public let state: GameState
    public let puzzle: Puzzle

    public init(state: GameState, puzzle: Puzzle) {
        self.state = state
        self.puzzle = puzzle
    }
}

public struct AppPreferences: Codable, Equatable, Sendable {
    public var textScale: Double
    public var highContrast: Bool
    public var soundEnabled: Bool
    public var hapticsEnabled: Bool
    public var timerEnabledByDefault: Bool
    public var checkMistakesByDefault: Bool
    public var reminderEnabled: Bool

    public init(
        textScale: Double = 1,
        highContrast: Bool = false,
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        timerEnabledByDefault: Bool = false,
        checkMistakesByDefault: Bool = false,
        reminderEnabled: Bool = false
    ) {
        self.textScale = textScale
        self.highContrast = highContrast
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.timerEnabledByDefault = timerEnabledByDefault
        self.checkMistakesByDefault = checkMistakesByDefault
        self.reminderEnabled = reminderEnabled
    }
}

public enum PersistenceError: Error, Sendable {
    case corruptSavedState(String)
    case statePuzzleMismatch
    case completionMissingDate
}

public enum PersistenceContainer {
    public static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            ActiveGameRecord.self,
            CompletedGameRecord.self,
            AppPreferencesRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

@ModelActor
public actor GamePersistenceStore {
    public static func make(modelContainer: ModelContainer) -> GamePersistenceStore {
        GamePersistenceStore(modelContainer: modelContainer)
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public func save(state: GameState, puzzle: Puzzle, now: Date = Date()) throws {
        guard state.puzzleID == puzzle.id else { throw PersistenceError.statePuzzleMismatch }

        let stateData = try encoder.encode(state)
        let puzzleData = try encoder.encode(puzzle)

        if state.status == .completed {
            guard let completedAt = state.completedAt else { throw PersistenceError.completionMissingDate }
            try upsertCompletion(
                state: state,
                puzzleData: puzzleData,
                stateData: stateData,
                completedAt: completedAt
            )
            try deleteActiveWithoutSaving(puzzleID: puzzle.id)
        } else {
            try upsertActive(
                state: state,
                puzzleData: puzzleData,
                stateData: stateData,
                now: now
            )
        }

        try modelContext.save()
    }

    public func loadProgress(puzzleID: String) throws -> SavedGame? {
        var descriptor = FetchDescriptor<ActiveGameRecord>(
            predicate: #Predicate { $0.puzzleID == puzzleID }
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else { return nil }
        return try decodeSavedGame(record)
    }

    public func loadMostRecentProgress() throws -> SavedGame? {
        var descriptor = FetchDescriptor<ActiveGameRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else { return nil }
        return try decodeSavedGame(record)
    }

    public func completionHistory() throws -> [CompletedGame] {
        let descriptor = FetchDescriptor<CompletedGameRecord>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { record in
            let state = try decoder.decode(GameState.self, from: record.finalStateData)
            let puzzle = try decoder.decode(Puzzle.self, from: record.puzzleSnapshotData)
            guard state.puzzleID == puzzle.id else { throw PersistenceError.statePuzzleMismatch }
            return CompletedGame(state: state, puzzle: puzzle)
        }
    }

    public func deleteProgress(puzzleID: String) throws {
        try deleteActiveWithoutSaving(puzzleID: puzzleID)
        try modelContext.save()
    }

    public func deleteAllLocalGameData() throws {
        for record in try modelContext.fetch(FetchDescriptor<ActiveGameRecord>()) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(FetchDescriptor<CompletedGameRecord>()) {
            modelContext.delete(record)
        }
        try modelContext.save()
    }

    public func loadPreferences() throws -> AppPreferences {
        var descriptor = FetchDescriptor<AppPreferencesRecord>(
            predicate: #Predicate { $0.singletonKey == "preferences" }
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else {
            return AppPreferences()
        }
        return AppPreferences(
            textScale: record.textScale,
            highContrast: record.highContrast,
            soundEnabled: record.soundEnabled,
            hapticsEnabled: record.hapticsEnabled,
            timerEnabledByDefault: record.timerEnabledByDefault,
            checkMistakesByDefault: record.checkMistakesByDefault,
            reminderEnabled: record.reminderEnabled
        )
    }

    public func savePreferences(_ preferences: AppPreferences, now: Date = Date()) throws {
        var descriptor = FetchDescriptor<AppPreferencesRecord>(
            predicate: #Predicate { $0.singletonKey == "preferences" }
        )
        descriptor.fetchLimit = 1

        let record: AppPreferencesRecord
        if let existing = try modelContext.fetch(descriptor).first {
            record = existing
        } else {
            record = AppPreferencesRecord()
            modelContext.insert(record)
        }

        record.textScale = min(max(preferences.textScale, 0.8), 2.0)
        record.highContrast = preferences.highContrast
        record.soundEnabled = preferences.soundEnabled
        record.hapticsEnabled = preferences.hapticsEnabled
        record.timerEnabledByDefault = preferences.timerEnabledByDefault
        record.checkMistakesByDefault = preferences.checkMistakesByDefault
        record.reminderEnabled = preferences.reminderEnabled
        record.updatedAt = now
        try modelContext.save()
    }

    private func upsertActive(
        state: GameState,
        puzzleData: Data,
        stateData: Data,
        now: Date
    ) throws {
        let puzzleID = state.puzzleID
        var descriptor = FetchDescriptor<ActiveGameRecord>(
            predicate: #Predicate { $0.puzzleID == puzzleID }
        )
        descriptor.fetchLimit = 1
        if let record = try modelContext.fetch(descriptor).first {
            record.sessionID = state.sessionID
            record.updatedAt = now
            record.stateData = stateData
            record.puzzleSnapshotData = puzzleData
        } else {
            modelContext.insert(ActiveGameRecord(
                puzzleID: puzzleID,
                sessionID: state.sessionID,
                updatedAt: now,
                stateData: stateData,
                puzzleSnapshotData: puzzleData
            ))
        }
    }

    private func upsertCompletion(
        state: GameState,
        puzzleData: Data,
        stateData: Data,
        completedAt: Date
    ) throws {
        let sessionID = state.sessionID
        var descriptor = FetchDescriptor<CompletedGameRecord>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )
        descriptor.fetchLimit = 1
        if let record = try modelContext.fetch(descriptor).first {
            record.puzzleID = state.puzzleID
            record.completedAt = completedAt
            record.elapsedSeconds = state.elapsedBeforeCurrentRun
            record.hintsUsed = state.hintsUsed
            record.checksUsed = state.checksUsed
            record.finalStateData = stateData
            record.puzzleSnapshotData = puzzleData
        } else {
            modelContext.insert(CompletedGameRecord(
                sessionID: sessionID,
                puzzleID: state.puzzleID,
                completedAt: completedAt,
                elapsedSeconds: state.elapsedBeforeCurrentRun,
                hintsUsed: state.hintsUsed,
                checksUsed: state.checksUsed,
                finalStateData: stateData,
                puzzleSnapshotData: puzzleData
            ))
        }
    }

    private func deleteActiveWithoutSaving(puzzleID: String) throws {
        let descriptor = FetchDescriptor<ActiveGameRecord>(
            predicate: #Predicate { $0.puzzleID == puzzleID }
        )
        for record in try modelContext.fetch(descriptor) {
            modelContext.delete(record)
        }
    }

    private func decodeSavedGame(_ record: ActiveGameRecord) throws -> SavedGame {
        do {
            let state = try decoder.decode(GameState.self, from: record.stateData)
            let puzzle = try decoder.decode(Puzzle.self, from: record.puzzleSnapshotData)
            guard state.puzzleID == puzzle.id else { throw PersistenceError.statePuzzleMismatch }
            try puzzle.validateRuntimeContract()
            return SavedGame(state: state, puzzle: puzzle, updatedAt: record.updatedAt)
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.corruptSavedState(String(describing: error))
        }
    }
}
#endif
