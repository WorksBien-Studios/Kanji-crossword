import Foundation
import KanjiGameCore

public struct PuzzleAccessPolicy: Sendable {
    public let freePuzzleIDs: Set<String>
    public var hasLifetimeUnlock: Bool

    public init(catalog: PuzzleCatalog, hasLifetimeUnlock: Bool) {
        self.freePuzzleIDs = Set(catalog.freePuzzleIDs(limit: 30))
        self.hasLifetimeUnlock = hasLifetimeUnlock
    }

    public func isUnlocked(_ puzzle: Puzzle) -> Bool {
        hasLifetimeUnlock || freePuzzleIDs.contains(puzzle.id)
    }
}
