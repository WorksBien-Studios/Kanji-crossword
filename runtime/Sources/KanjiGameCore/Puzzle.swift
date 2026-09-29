import Foundation

public enum PuzzleMode: String, Codable, CaseIterable, Sendable {
    case kanjiNankuro
    case kanjiNankuroLarge
}

public enum PuzzleDifficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case standard
    case hard
    case expert
}

public struct DifficultyMetrics: Codable, Equatable, Sendable {
    public let clueScarcity: Double
    public let maxLogicDepth: Int
    public let averageLogicDepth: Double
    public let branchingBits: Double

    public init(
        clueScarcity: Double,
        maxLogicDepth: Int,
        averageLogicDepth: Double,
        branchingBits: Double
    ) {
        self.clueScarcity = clueScarcity
        self.maxLogicDepth = maxLogicDepth
        self.averageLogicDepth = averageLogicDepth
        self.branchingBits = branchingBits
    }
}

public struct WordSpan: Codable, Equatable, Sendable {
    public let word: String
    public let reading: String
    public let cells: [String]

    public init(word: String, reading: String, cells: [String]) {
        self.word = word
        self.reading = reading
        self.cells = cells
    }
}

public struct CellCoordinate: Codable, Hashable, Comparable, Sendable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    public init?(_ encoded: String) {
        let parts = encoded.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let row = Int(parts[0]),
              let column = Int(parts[1]) else {
            return nil
        }
        self.init(row: row, column: column)
    }

    public var encoded: String { "\(row),\(column)" }

    public static func < (lhs: CellCoordinate, rhs: CellCoordinate) -> Bool {
        lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
    }
}

public struct Puzzle: Codable, Equatable, Sendable, Identifiable {
    public let schemaVersion: Int
    public let mode: PuzzleMode
    public let difficulty: PuzzleDifficulty
    public let difficultyScore: Double
    public let difficultyMetrics: DifficultyMetrics
    public let rows: Int
    public let columns: Int
    public let cellLayout: [[String]]
    public let cellNumbers: [String: Int]
    public let solution: [String: String]
    public let starterCells: [String: String]
    public let wordSpans: [WordSpan]
    public let editorialStatus: String
    public let editorialNotes: String
    public let sourceNotes: String
    public let id: String
    public let traySeed: [String]
    public let validationDigest: String

    public init(
        schemaVersion: Int,
        mode: PuzzleMode,
        difficulty: PuzzleDifficulty,
        difficultyScore: Double,
        difficultyMetrics: DifficultyMetrics,
        rows: Int,
        columns: Int,
        cellLayout: [[String]],
        cellNumbers: [String: Int],
        solution: [String: String],
        starterCells: [String: String],
        wordSpans: [WordSpan],
        editorialStatus: String,
        editorialNotes: String,
        sourceNotes: String,
        id: String,
        traySeed: [String],
        validationDigest: String
    ) {
        self.schemaVersion = schemaVersion
        self.mode = mode
        self.difficulty = difficulty
        self.difficultyScore = difficultyScore
        self.difficultyMetrics = difficultyMetrics
        self.rows = rows
        self.columns = columns
        self.cellLayout = cellLayout
        self.cellNumbers = cellNumbers
        self.solution = solution
        self.starterCells = starterCells
        self.wordSpans = wordSpans
        self.editorialStatus = editorialStatus
        self.editorialNotes = editorialNotes
        self.sourceNotes = sourceNotes
        self.id = id
        self.traySeed = traySeed
        self.validationDigest = validationDigest
    }

    public var solutionByNumber: [Int: String] {
        Dictionary(uniqueKeysWithValues: solution.compactMap { key, value in
            Int(key).map { ($0, value) }
        })
    }

    public var startersByNumber: [Int: String] {
        Dictionary(uniqueKeysWithValues: starterCells.compactMap { key, value in
            Int(key).map { ($0, value) }
        })
    }

    public var editableNumbers: Set<Int> {
        Set(solutionByNumber.keys).subtracting(startersByNumber.keys)
    }

    public func number(at coordinate: CellCoordinate) -> Int? {
        cellNumbers[coordinate.encoded]
    }

    public func coordinates(for number: Int) -> [CellCoordinate] {
        cellNumbers.compactMap { key, value in
            guard value == number else { return nil }
            return CellCoordinate(key)
        }.sorted()
    }
}

public enum PuzzleValidationError: Error, Equatable, CustomStringConvertible, Sendable {
    case unsupportedSchema(Int)
    case malformedID(String)
    case invalidDimensions
    case invalidLayout(row: Int)
    case invalidCoordinate(String)
    case numberedBlockedCell(String)
    case missingSolutionNumber(Int)
    case extraSolutionNumber(Int)
    case invalidStarter(Int)
    case invalidTray
    case invalidWordSpan(String)
    case invalidDigest(String)

    public var description: String {
        switch self {
        case .unsupportedSchema(let version): return "Unsupported schema version: \(version)"
        case .malformedID(let id): return "Malformed content-addressed ID: \(id)"
        case .invalidDimensions: return "Puzzle dimensions do not match the layout"
        case .invalidLayout(let row): return "Invalid layout row: \(row)"
        case .invalidCoordinate(let value): return "Invalid cell coordinate: \(value)"
        case .numberedBlockedCell(let value): return "Numbered cell is blocked: \(value)"
        case .missingSolutionNumber(let number): return "Missing solution for number: \(number)"
        case .extraSolutionNumber(let number): return "Solution contains unused number: \(number)"
        case .invalidStarter(let number): return "Starter does not match the solution for number: \(number)"
        case .invalidTray: return "Answer tray does not exactly match solution kanji"
        case .invalidWordSpan(let word): return "Invalid word span: \(word)"
        case .invalidDigest(let digest): return "Invalid validation digest: \(digest)"
        }
    }
}

extension Puzzle {
    public func validateRuntimeContract() throws {
        guard schemaVersion == 2 else { throw PuzzleValidationError.unsupportedSchema(schemaVersion) }
        guard id.hasPrefix("nankuro-v2-"), id.count > "nankuro-v2-".count else {
            throw PuzzleValidationError.malformedID(id)
        }
        guard rows > 0, columns > 0, cellLayout.count == rows else {
            throw PuzzleValidationError.invalidDimensions
        }
        for (rowIndex, row) in cellLayout.enumerated() {
            guard row.count == columns, row.allSatisfy({ $0 == "." || $0 == "#" }) else {
                throw PuzzleValidationError.invalidLayout(row: rowIndex)
            }
        }

        let numberedValues = Set(cellNumbers.values)
        for (encoded, number) in cellNumbers {
            guard let coordinate = CellCoordinate(encoded),
                  coordinate.row >= 0,
                  coordinate.row < rows,
                  coordinate.column >= 0,
                  coordinate.column < columns else {
                throw PuzzleValidationError.invalidCoordinate(encoded)
            }
            guard cellLayout[coordinate.row][coordinate.column] == "." else {
                throw PuzzleValidationError.numberedBlockedCell(encoded)
            }
            guard solution[String(number)] != nil else {
                throw PuzzleValidationError.missingSolutionNumber(number)
            }
        }

        for key in solution.keys {
            guard let number = Int(key), numberedValues.contains(number) else {
                throw PuzzleValidationError.extraSolutionNumber(Int(key) ?? -1)
            }
        }

        for (key, kanji) in starterCells {
            guard let number = Int(key), solution[key] == kanji else {
                throw PuzzleValidationError.invalidStarter(Int(key) ?? -1)
            }
            guard numberedValues.contains(number) else {
                throw PuzzleValidationError.invalidStarter(number)
            }
        }

        let solutionValues = solution.values.sorted()
        guard traySeed.sorted() == solutionValues,
              Set(traySeed).count == traySeed.count else {
            throw PuzzleValidationError.invalidTray
        }

        for span in wordSpans {
            let characters = Array(span.word).map(String.init)
            guard characters.count == span.cells.count,
                  !span.reading.isEmpty else {
                throw PuzzleValidationError.invalidWordSpan(span.word)
            }
            for (index, encoded) in span.cells.enumerated() {
                guard let coordinate = CellCoordinate(encoded),
                      let number = cellNumbers[coordinate.encoded],
                      solution[String(number)] == characters[index] else {
                    throw PuzzleValidationError.invalidWordSpan(span.word)
                }
            }
        }

        let isHex = validationDigest.count == 64 && validationDigest.unicodeScalars.allSatisfy {
            switch $0.value {
            case 48...57, 97...102: true
            default: false
            }
        }
        guard isHex else { throw PuzzleValidationError.invalidDigest(validationDigest) }
    }
}
