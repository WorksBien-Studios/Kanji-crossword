import Foundation
import KanjiGameCore

enum ContentCheckError: Error, CustomStringConvertible {
    case usage

    var description: String {
        "Usage: KanjiContentCheck <puzzles-v2.json>"
    }
}

@main
struct KanjiContentCheck {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw ContentCheckError.usage
        }

        let path = CommandLine.arguments[1]
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let catalog = try PuzzleCatalog.decode(data, enforceLaunchLibrary: true)

        let freeIDs = catalog.freePuzzleIDs()
        guard freeIDs.count == 30 else {
            throw PuzzleCatalogError.wrongLaunchCount(expected: 30, actual: freeIDs.count)
        }

        let freePuzzles = freeIDs.compactMap { catalog[$0] }
        let modes = Set(freePuzzles.map(\.mode))
        let difficulties = Set(freePuzzles.map(\.difficulty))
        guard modes == Set(PuzzleMode.allCases),
              difficulties == Set(PuzzleDifficulty.allCases) else {
            throw ContentCheckError.usage
        }

        print("PASS: \(catalog.puzzles.count) runtime-decodable puzzles; 30-puzzle free set covers both modes and all difficulties")
    }
}
