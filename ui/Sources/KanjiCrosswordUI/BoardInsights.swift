import Foundation
import KanjiGameCore

/// One character position inside a word, with whatever the player has entered.
struct WordSlot: Equatable {
    let number: Int
    let kanji: String?
}

/// Pure helpers that describe how the words of a puzzle connect. Most puzzles
/// share a kanji between words by sharing one cell; a minority repeat a number
/// across several cells. Both are handled here.
struct BoardInsights {
    let puzzle: Puzzle

    func numbers(in span: WordSpan) -> [Int] {
        span.cells.compactMap { puzzle.cellNumbers[$0] }
    }

    func words(containing number: Int) -> [WordSpan] {
        puzzle.wordSpans.filter { numbers(in: $0).contains(number) }
    }

    /// Numbers that sit in the same words as `number`, excluding `number`.
    func relatedNumbers(of number: Int?) -> Set<Int> {
        guard let number else { return [] }
        var related = Set<Int>()
        for span in words(containing: number) {
            related.formUnion(numbers(in: span))
        }
        related.remove(number)
        return related
    }

    func slots(for span: WordSpan, entries: [Int: String]) -> [WordSlot] {
        numbers(in: span).map { WordSlot(number: $0, kanji: entries[$0]) }
    }

    /// Coordinate keys ("row,column") of a word, for highlighting on a board.
    func cellKeys(of span: WordSpan) -> Set<String> {
        Set(span.cells)
    }
}

/// Month layout for the records calendar.
struct MonthGrid: Equatable {
    let leadingBlanks: Int
    let dayCount: Int
    let weekdaySymbols: [String]

    static func make(for date: Date, calendar: Calendar) -> MonthGrid {
        let start = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) ?? date
        let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let weekday = calendar.component(.weekday, from: start)
        let blanks = (weekday - calendar.firstWeekday + 7) % 7
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first...]) + Array(symbols[..<first])
        return MonthGrid(
            leadingBlanks: blanks,
            dayCount: dayCount,
            weekdaySymbols: ordered
        )
    }
}

enum PlayStats {
    /// Day-of-month numbers, within the month of `reference`, that have at
    /// least one date in `dates`.
    static func playedDays(
        _ dates: [Date],
        inMonthOf reference: Date,
        calendar: Calendar
    ) -> Set<Int> {
        var days = Set<Int>()
        for date in dates {
            if calendar.isDate(date, equalTo: reference, toGranularity: .month) {
                days.insert(calendar.component(.day, from: date))
            }
        }
        return days
    }
}

enum JapaneseDateText {
    /// "令和8年9月29日 火曜日"
    static func eraDate(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = timeZone
        formatter.dateFormat = "GGGGy年M月d日 EEEE"
        return formatter.string(from: date)
    }

    /// "令和8年 9月"
    static func eraMonth(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = timeZone
        formatter.dateFormat = "GGGGy年 M月"
        return formatter.string(from: date)
    }
}

enum PuzzleSequence {
    /// The next puzzle after `id` in `list`, wrapping around at the end, that
    /// satisfies `isEligible`. The puzzle `id` itself is never returned.
    static func next(
        after id: String,
        in list: [Puzzle],
        where isEligible: (Puzzle) -> Bool
    ) -> Puzzle? {
        guard let index = list.firstIndex(where: { $0.id == id }) else { return nil }
        let following = Array(list[(index + 1)...]) + Array(list[..<index])
        return following.first(where: isEligible)
    }
}
