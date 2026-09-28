import Foundation
import Testing
@testable import KanjiGameCore

@Suite("Puzzle contract")
struct PuzzleCatalogTests {
    @Test("valid puzzle passes runtime validation")
    func validPuzzle() throws {
        try samplePuzzle().validateRuntimeContract()
    }

    @Test("tray must exactly match unique solution kanji")
    func badTray() {
        let base = samplePuzzle()
        let bad = Puzzle(
            schemaVersion: base.schemaVersion,
            mode: base.mode,
            difficulty: base.difficulty,
            difficultyScore: base.difficultyScore,
            difficultyMetrics: base.difficultyMetrics,
            rows: base.rows,
            columns: base.columns,
            cellLayout: base.cellLayout,
            cellNumbers: base.cellNumbers,
            solution: base.solution,
            starterCells: base.starterCells,
            wordSpans: base.wordSpans,
            editorialStatus: base.editorialStatus,
            editorialNotes: base.editorialNotes,
            sourceNotes: base.sourceNotes,
            id: base.id,
            traySeed: ["日", "本", "本"],
            validationDigest: base.validationDigest
        )
        #expect(throws: PuzzleValidationError.invalidTray) {
            try bad.validateRuntimeContract()
        }
    }

    @Test("small catalogs can be decoded for tests and previews")
    func decodeSmallCatalog() throws {
        let data = try JSONEncoder().encode([samplePuzzle()])
        let catalog = try PuzzleCatalog.decode(
            data,
            enforceLaunchLibrary: false
        )
        #expect(catalog.puzzles.count == 1)
        #expect(catalog[samplePuzzle().id] != nil)
    }
}
