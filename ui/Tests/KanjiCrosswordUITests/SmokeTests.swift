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

    @Test("Privacy policy uses the canonical WorksBien route")
    func privacyPolicyURL() {
        #expect(
            KanjiPolicyLinks.privacy.absoluteString
                == "https://worksbienstudios.com/apps/kanji-crossword/privacy/"
        )
    }

    @Test("JMdict/EDRDG attribution links stay locked to the licensed sources")
    func attributionLinks() {
        #expect(
            KanjiPolicyLinks.jmdictProject.absoluteString == "http://www.edrdg.org/"
        )
        #expect(
            KanjiPolicyLinks.ccBySa30.absoluteString
                == "https://creativecommons.org/licenses/by-sa/3.0/"
        )
    }

    @Test("Japanese difficulty labels remain stable")
    func difficultyLabels() {
        #expect(PuzzleDifficulty.easy.japaneseTitle == "やさしい")
        #expect(PuzzleDifficulty.standard.japaneseTitle == "ふつう")
        #expect(PuzzleDifficulty.hard.japaneseTitle == "むずかしい")
        #expect(PuzzleDifficulty.expert.japaneseTitle == "達人")
    }
}
