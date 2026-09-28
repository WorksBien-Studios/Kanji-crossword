import Foundation

public enum PuzzleCatalogError: Error, Equatable, CustomStringConvertible, Sendable {
    case decodingFailed(String)
    case invalidPuzzle(id: String, reason: String)
    case duplicateID(String)
    case wrongLaunchCount(expected: Int, actual: Int)
    case wrongModeCount(mode: PuzzleMode, expected: Int, actual: Int)

    public var description: String {
        switch self {
        case .decodingFailed(let reason): return "Could not decode puzzle library: \(reason)"
        case .invalidPuzzle(let id, let reason): return "Invalid puzzle \(id): \(reason)"
        case .duplicateID(let id): return "Duplicate puzzle ID: \(id)"
        case .wrongLaunchCount(let expected, let actual): return "Expected \(expected) puzzles, found \(actual)"
        case .wrongModeCount(let mode, let expected, let actual):
            return "Expected \(expected) \(mode.rawValue) puzzles, found \(actual)"
        }
    }
}

public struct PuzzleCatalog: Sendable {
    public let puzzles: [Puzzle]
    private let byID: [String: Puzzle]

    public init(puzzles: [Puzzle], enforceLaunchLibrary: Bool = true) throws {
        var seen = Set<String>()
        for puzzle in puzzles {
            do {
                try puzzle.validateRuntimeContract()
            } catch {
                throw PuzzleCatalogError.invalidPuzzle(id: puzzle.id, reason: String(describing: error))
            }
            guard seen.insert(puzzle.id).inserted else {
                throw PuzzleCatalogError.duplicateID(puzzle.id)
            }
        }

        if enforceLaunchLibrary {
            guard puzzles.count == 360 else {
                throw PuzzleCatalogError.wrongLaunchCount(expected: 360, actual: puzzles.count)
            }
            let standard = puzzles.filter { $0.mode == .kanjiNankuro }.count
            let large = puzzles.filter { $0.mode == .kanjiNankuroLarge }.count
            guard standard == 240 else {
                throw PuzzleCatalogError.wrongModeCount(mode: .kanjiNankuro, expected: 240, actual: standard)
            }
            guard large == 120 else {
                throw PuzzleCatalogError.wrongModeCount(mode: .kanjiNankuroLarge, expected: 120, actual: large)
            }
        }

        self.puzzles = puzzles
        self.byID = Dictionary(uniqueKeysWithValues: puzzles.map { ($0.id, $0) })
    }

    public static func decode(_ data: Data, enforceLaunchLibrary: Bool = true) throws -> PuzzleCatalog {
        let puzzles: [Puzzle]
        do {
            puzzles = try JSONDecoder().decode([Puzzle].self, from: data)
        } catch {
            throw PuzzleCatalogError.decodingFailed(String(describing: error))
        }
        return try PuzzleCatalog(puzzles: puzzles, enforceLaunchLibrary: enforceLaunchLibrary)
    }

    public subscript(id: String) -> Puzzle? { byID[id] }

    public func puzzles(mode: PuzzleMode, difficulty: PuzzleDifficulty? = nil) -> [Puzzle] {
        puzzles.filter { puzzle in
            puzzle.mode == mode && (difficulty == nil || puzzle.difficulty == difficulty)
        }
    }

    public func freePuzzleIDs(limit: Int = 30) -> [String] {
        guard limit > 0 else { return [] }

        let buckets: [(PuzzleMode, PuzzleDifficulty)] = PuzzleMode.allCases.flatMap { mode in
            PuzzleDifficulty.allCases.map { (mode, $0) }
        }
        var bucketIndex = Dictionary(uniqueKeysWithValues: buckets.map {
            ($0.0.rawValue + ":" + $0.1.rawValue, 0)
        })
        var result: [String] = []
        var exhaustedPasses = 0

        while result.count < min(limit, puzzles.count), exhaustedPasses < buckets.count {
            var addedThisPass = false
            for (mode, difficulty) in buckets where result.count < limit {
                let key = mode.rawValue + ":" + difficulty.rawValue
                let candidates = puzzles.filter { $0.mode == mode && $0.difficulty == difficulty }
                let index = bucketIndex[key, default: 0]
                guard index < candidates.count else { continue }
                let id = candidates[index].id
                bucketIndex[key] = index + 1
                if !result.contains(id) {
                    result.append(id)
                    addedThisPass = true
                }
            }
            exhaustedPasses = addedThisPass ? 0 : exhaustedPasses + 1
        }

        if result.count < min(limit, puzzles.count) {
            for puzzle in puzzles where result.count < limit && !result.contains(puzzle.id) {
                result.append(puzzle.id)
            }
        }
        return result
    }
}
