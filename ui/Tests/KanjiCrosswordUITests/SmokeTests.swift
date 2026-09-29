import Testing
@testable import KanjiCrosswordUI
import KanjiGameCore

@Suite("UI shell contracts")
struct SmokeTests {
    @Test("Japanese mode labels remain stable")
    func modeLabels() {
        #expect(PuzzleMode.kanjiNankuro.japaneseTitle == "漢字ナンクロ")
        #expect(PuzzleMode.kanjiNankuroLarge.japaneseTitle == "大盤面")
    }

    @Test("Japanese difficulty labels remain stable")
    func difficultyLabels() {
        #expect(PuzzleDifficulty.easy.japaneseTitle == "やさしい")
        #expect(PuzzleDifficulty.standard.japaneseTitle == "ふつう")
        #expect(PuzzleDifficulty.hard.japaneseTitle == "むずかしい")
        #expect(PuzzleDifficulty.expert.japaneseTitle == "達人")
    }
}
