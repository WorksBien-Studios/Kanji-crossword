import Foundation
import KanjiGameCore

enum ResultMetrics {
    /// Counts a correction when a wrong committed answer is replaced by the
    /// right answer. Undoing, erasing, or changing one wrong answer to another
    /// does not inflate the result.
    static func correctionCount(state: GameState, puzzle: Puzzle) -> Int {
        state.undoStack.reduce(into: 0) { count, move in
            guard let answer = puzzle.solutionByNumber[move.number],
                  let previous = move.previousKanji,
                  previous != answer,
                  move.newKanji == answer else { return }
            count += 1
        }
    }

    /// Personal best is meaningful only for completed, timed attempts of the
    /// same immutable puzzle. Zero-duration fixture runs are ignored.
    static func personalBest(
        puzzleID: String,
        states: [GameState]
    ) -> TimeInterval? {
        states.lazy
            .filter {
                $0.puzzleID == puzzleID
                    && $0.status == .completed
                    && $0.timerEnabled
                    && $0.elapsedBeforeCurrentRun > 0
            }
            .map(\.elapsedBeforeCurrentRun)
            .min()
    }
}
