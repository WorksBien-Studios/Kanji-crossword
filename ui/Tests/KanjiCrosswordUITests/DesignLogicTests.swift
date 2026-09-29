import Foundation
import Testing
@testable import KanjiCrosswordUI
import KanjiGameCore

@Suite("Board insights and calendar helpers")
struct DesignLogicTests {
    /// Three squares in a row. Numbers 1 and 3 share a kanji, so number 1
    /// appears in two cells, and 日本 / 本日 both cross the middle square.
    private var puzzle: Puzzle {
        Puzzle(
            schemaVersion: 2,
            mode: .kanjiNankuro,
            difficulty: .easy,
            difficultyScore: 0.1,
            difficultyMetrics: DifficultyMetrics(
                clueScarcity: 0,
                maxLogicDepth: 1,
                averageLogicDepth: 1,
                branchingBits: 0
            ),
            rows: 1,
            columns: 3,
            cellLayout: [[".", ".", "."]],
            cellNumbers: ["0,0": 1, "0,1": 2, "0,2": 1],
            solution: ["1": "日", "2": "本"],
            starterCells: [:],
            wordSpans: [
                WordSpan(word: "日本", reading: "にほん", cells: ["0,0", "0,1"]),
                WordSpan(word: "本日", reading: "ほんじつ", cells: ["0,1", "0,2"])
            ],
            editorialStatus: "test",
            editorialNotes: "",
            sourceNotes: "",
            id: "nankuro-v2-test",
            traySeed: ["日", "本"],
            validationDigest: String(repeating: "0", count: 64)
        )
    }

    @Test("Words containing a number are found through every cell it occupies")
    func wordsContainingNumber() {
        let insights = BoardInsights(puzzle: puzzle)
        #expect(insights.words(containing: 1).map(\.word) == ["日本", "本日"])
        #expect(insights.words(containing: 2).count == 2)
    }

    @Test("Related numbers exclude the selected number itself")
    func relatedNumbers() {
        let insights = BoardInsights(puzzle: puzzle)
        #expect(insights.relatedNumbers(of: 1) == [2])
        #expect(insights.relatedNumbers(of: 2) == [1])
        #expect(insights.relatedNumbers(of: nil).isEmpty)
    }

    @Test("Word slots show only what the player has entered")
    func slots() {
        let insights = BoardInsights(puzzle: puzzle)
        let span = puzzle.wordSpans[0]
        let slots = insights.slots(for: span, entries: [1: "日"])
        #expect(slots == [
            WordSlot(number: 1, kanji: "日"),
            WordSlot(number: 2, kanji: nil)
        ])
    }

    @Test("September 2026 starts on a Tuesday and has 30 days")
    func monthGrid() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 29))!
        let grid = MonthGrid.make(for: date, calendar: calendar)
        #expect(grid.leadingBlanks == 2)
        #expect(grid.dayCount == 30)
        #expect(grid.weekdaySymbols.count == 7)
    }

    @Test("Played days only count within the shown month")
    func playedDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        func day(_ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
        }
        let played = PlayStats.playedDays(
            [day(9, 1), day(9, 1), day(9, 28), day(8, 31)],
            inMonthOf: day(9, 29),
            calendar: calendar
        )
        #expect(played == [1, 28])
    }

    @Test("Era date reads in the Reiwa calendar")
    func eraDate() {
        var calendar = Calendar(identifier: .gregorian)
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        calendar.timeZone = tokyo
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 29, hour: 12))!
        #expect(JapaneseDateText.eraDate(date, timeZone: tokyo) == "令和8年9月29日 火曜日")
    }

    private func makePuzzle(id: String) -> Puzzle {
        let base = self.puzzle
        return Puzzle(
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
            id: id,
            traySeed: base.traySeed,
            validationDigest: base.validationDigest
        )
    }

    @Test("Next puzzle skips ineligible ones and wraps around")
    func nextPuzzle() {
        let list = ["a", "b", "c", "d"].map { makePuzzle(id: $0) }
        let skipB = PuzzleSequence.next(after: "a", in: list) { $0.id != "b" }
        #expect(skipB?.id == "c")
        let wrapped = PuzzleSequence.next(after: "d", in: list) { $0.id == "a" }
        #expect(wrapped?.id == "a")
    }

    @Test("Next puzzle is nil when nothing else is eligible or the id is unknown")
    func nextPuzzleNone() {
        let list = ["a", "b"].map { makePuzzle(id: $0) }
        #expect(PuzzleSequence.next(after: "a", in: list) { _ in false } == nil)
        #expect(PuzzleSequence.next(after: "a", in: list) { $0.id == "a" } == nil)
        #expect(PuzzleSequence.next(after: "zzz", in: list) { _ in true } == nil)
    }
}
