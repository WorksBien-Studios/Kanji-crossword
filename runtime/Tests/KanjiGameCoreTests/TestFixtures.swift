import Foundation
import KanjiGameCore

func samplePuzzle(id: String = "nankuro-v2-0123456789abcdefabcd") -> Puzzle {
    Puzzle(
        schemaVersion: 2,
        mode: .kanjiNankuro,
        difficulty: .standard,
        difficultyScore: 0.5,
        difficultyMetrics: DifficultyMetrics(
            clueScarcity: 0.5,
            maxLogicDepth: 3,
            averageLogicDepth: 1.5,
            branchingBits: 0.25
        ),
        rows: 2,
        columns: 2,
        cellLayout: [[".", "."], [".", "."]],
        cellNumbers: ["0,0": 1, "0,1": 2, "1,0": 1, "1,1": 3],
        solution: ["1": "日", "2": "本", "3": "語"],
        starterCells: ["1": "日"],
        wordSpans: [
            WordSpan(word: "日本", reading: "にほん", cells: ["0,0", "0,1"]),
            WordSpan(word: "日語", reading: "にちご", cells: ["1,0", "1,1"])
        ],
        editorialStatus: "ai_review_passed_owner_approved",
        editorialNotes: "test",
        sourceNotes: "test",
        id: id,
        traySeed: ["語", "日", "本"],
        validationDigest: String(repeating: "a", count: 64)
    )
}
