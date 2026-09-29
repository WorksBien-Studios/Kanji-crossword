import Foundation

public enum GameStatus: String, Codable, Equatable, Sendable {
    case active
    case paused
    case completed
}

public struct BoardViewport: Codable, Equatable, Sendable {
    public var zoomScale: Double
    public var centerRow: Double
    public var centerColumn: Double

    public init(zoomScale: Double = 1, centerRow: Double = 0, centerColumn: Double = 0) {
        self.zoomScale = zoomScale
        self.centerRow = centerRow
        self.centerColumn = centerColumn
    }

    public mutating func normalize(rows: Int, columns: Int) {
        zoomScale = min(max(zoomScale, 1), 4)
        centerRow = min(max(centerRow, 0), Double(max(0, rows - 1)))
        centerColumn = min(max(centerColumn, 0), Double(max(0, columns - 1)))
    }
}

public struct MoveRecord: Codable, Equatable, Sendable {
    public let number: Int
    public let previousKanji: String?
    public let newKanji: String?

    public init(number: Int, previousKanji: String?, newKanji: String?) {
        self.number = number
        self.previousKanji = previousKanji
        self.newKanji = newKanji
    }
}

public struct GameState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let sessionID: UUID
    public let puzzleID: String
    public var status: GameStatus
    public var entries: [Int: String]
    public var selectedNumber: Int?
    public var viewport: BoardViewport
    public var undoStack: [MoveRecord]
    public var redoStack: [MoveRecord]
    public var hintsUsed: Int
    public var checksUsed: Int
    public let startedAt: Date
    public var completedAt: Date?
    public var timerEnabled: Bool
    public var elapsedBeforeCurrentRun: TimeInterval
    public var timerRunningSince: Date?

    public init(
        puzzle: Puzzle,
        timerEnabled: Bool,
        now: Date = Date(),
        sessionID: UUID = UUID()
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.sessionID = sessionID
        self.puzzleID = puzzle.id
        self.status = .active
        self.entries = puzzle.startersByNumber
        self.selectedNumber = nil
        self.viewport = BoardViewport()
        self.undoStack = []
        self.redoStack = []
        self.hintsUsed = 0
        self.checksUsed = 0
        self.startedAt = now
        self.completedAt = nil
        self.timerEnabled = timerEnabled
        self.elapsedBeforeCurrentRun = 0
        self.timerRunningSince = timerEnabled ? now : nil
    }

    public func elapsedTime(at now: Date = Date()) -> TimeInterval {
        guard timerEnabled, let timerRunningSince else { return elapsedBeforeCurrentRun }
        return elapsedBeforeCurrentRun + max(0, now.timeIntervalSince(timerRunningSince))
    }

    public func isSolved(puzzle: Puzzle) -> Bool {
        guard puzzle.id == puzzleID else { return false }
        return puzzle.solutionByNumber.allSatisfy { number, answer in
            entries[number] == answer
        }
    }

    public func wrongNumbers(puzzle: Puzzle) -> [Int] {
        guard puzzle.id == puzzleID else { return [] }
        return entries.compactMap { number, value in
            guard puzzle.startersByNumber[number] == nil,
                  let answer = puzzle.solutionByNumber[number],
                  value != answer else { return nil }
            return number
        }.sorted()
    }
}
