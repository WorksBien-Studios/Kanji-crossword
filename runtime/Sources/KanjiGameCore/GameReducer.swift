import Foundation

public enum GameAction: Equatable, Sendable {
    case selectNumber(Int?)
    case enterKanji(String)
    case eraseSelected
    case undo
    case redo
    case requestHint
    case checkMistakes
    case updateViewport(BoardViewport)
    case pause
    case resume
    case restartConfirmed
}

public struct HintExplanation: Equatable, Sendable {
    public enum Reason: Equatable, Sendable {
        case crossingWords
        case constrainedWord
        case validatedUniqueSolution
    }

    public let number: Int
    public let kanji: String
    public let reason: Reason
    public let relatedWords: [WordSpan]

    public init(number: Int, kanji: String, reason: Reason, relatedWords: [WordSpan]) {
        self.number = number
        self.kanji = kanji
        self.reason = reason
        self.relatedWords = relatedWords
    }
}

public enum GameEvent: Equatable, Sendable {
    case none
    case hint(HintExplanation)
    case mistakes([Int])
    case completed
}

public struct GameTransition: Equatable, Sendable {
    public let state: GameState
    public let event: GameEvent
    public let didChangeState: Bool

    public init(state: GameState, event: GameEvent, didChangeState: Bool) {
        self.state = state
        self.event = event
        self.didChangeState = didChangeState
    }
}

public enum GameReducerError: Error, Equatable, Sendable {
    case puzzleMismatch
    case unsupportedStateSchema(Int)
}

public enum GameReducer {
    public static func reduce(
        state original: GameState,
        action: GameAction,
        puzzle: Puzzle,
        now: Date = Date()
    ) throws -> GameTransition {
        guard original.schemaVersion == GameState.currentSchemaVersion else {
            throw GameReducerError.unsupportedStateSchema(original.schemaVersion)
        }
        guard original.puzzleID == puzzle.id else { throw GameReducerError.puzzleMismatch }

        var state = original
        var event: GameEvent = .none

        switch action {
        case .selectNumber(let number):
            if let number, !puzzle.solutionByNumber.keys.contains(number) {
                break
            }
            state.selectedNumber = number

        case .enterKanji(let kanji):
            guard state.status == .active,
                  let number = state.selectedNumber,
                  puzzle.editableNumbers.contains(number),
                  kanji.count == 1,
                  puzzle.traySeed.contains(kanji) else { break }
            applyEntry(number: number, newValue: kanji, to: &state)

        case .eraseSelected:
            guard state.status == .active,
                  let number = state.selectedNumber,
                  puzzle.editableNumbers.contains(number),
                  state.entries[number] != nil else { break }
            applyEntry(number: number, newValue: nil, to: &state)

        case .undo:
            guard state.status == .active, let move = state.undoStack.popLast() else { break }
            set(move.previousKanji, for: move.number, in: &state.entries)
            state.redoStack.append(move)

        case .redo:
            guard state.status == .active, let move = state.redoStack.popLast() else { break }
            set(move.newKanji, for: move.number, in: &state.entries)
            state.undoStack.append(move)

        case .requestHint:
            guard state.status == .active,
                  let hint = bestHint(state: state, puzzle: puzzle) else { break }
            state.hintsUsed += 1
            state.selectedNumber = hint.number
            applyEntry(number: hint.number, newValue: hint.kanji, to: &state)
            event = .hint(hint)

        case .checkMistakes:
            guard state.status == .active else { break }
            state.checksUsed += 1
            event = .mistakes(state.wrongNumbers(puzzle: puzzle))

        case .updateViewport(var viewport):
            viewport.normalize(rows: puzzle.rows, columns: puzzle.columns)
            state.viewport = viewport

        case .pause:
            guard state.status == .active else { break }
            pauseTimer(&state, now: now)
            state.status = .paused

        case .resume:
            guard state.status == .paused else { break }
            state.status = .active
            if state.timerEnabled { state.timerRunningSince = now }

        case .restartConfirmed:
            guard state.status != .completed else { break }
            let timerEnabled = state.timerEnabled
            let sessionID = state.sessionID
            state = GameState(puzzle: puzzle, timerEnabled: timerEnabled, now: now, sessionID: sessionID)
        }

        if state.status == .active,
           state.isSolved(puzzle: puzzle),
           original.status != .completed {
            pauseTimer(&state, now: now)
            state.status = .completed
            state.completedAt = now
            event = .completed
        }

        return GameTransition(state: state, event: event, didChangeState: state != original)
    }

    private static func applyEntry(number: Int, newValue: String?, to state: inout GameState) {
        let previous = state.entries[number]
        guard previous != newValue else { return }
        state.undoStack.append(MoveRecord(number: number, previousKanji: previous, newKanji: newValue))
        state.redoStack.removeAll(keepingCapacity: true)
        set(newValue, for: number, in: &state.entries)
    }

    private static func set(_ value: String?, for number: Int, in entries: inout [Int: String]) {
        if let value {
            entries[number] = value
        } else {
            entries.removeValue(forKey: number)
        }
    }

    private static func pauseTimer(_ state: inout GameState, now: Date) {
        guard state.timerEnabled, let runningSince = state.timerRunningSince else { return }
        state.elapsedBeforeCurrentRun += max(0, now.timeIntervalSince(runningSince))
        state.timerRunningSince = nil
    }

    private static func bestHint(state: GameState, puzzle: Puzzle) -> HintExplanation? {
        let unresolved = puzzle.editableNumbers
            .filter { state.entries[$0] != puzzle.solutionByNumber[$0] }
            .sorted()
        guard !unresolved.isEmpty else { return nil }

        let scored = unresolved.compactMap { number -> (Int, Int, [WordSpan])? in
            guard puzzle.solutionByNumber[number] != nil else { return nil }
            let coordinates = Set(puzzle.coordinates(for: number).map(\.encoded))
            let related = puzzle.wordSpans.filter { span in
                !coordinates.isDisjoint(with: span.cells)
            }
            let knownPressure = related.reduce(into: 0) { score, span in
                for cell in span.cells {
                    guard let mapped = puzzle.cellNumbers[cell] else { continue }
                    if state.entries[mapped] == puzzle.solutionByNumber[mapped] { score += 1 }
                }
            }
            return (knownPressure, related.count, related)
        }

        guard let best = scored.enumerated().max(by: { lhs, rhs in
            let left = lhs.element
            let right = rhs.element
            if left.0 != right.0 { return left.0 < right.0 }
            if left.1 != right.1 { return left.1 < right.1 }
            return unresolved[lhs.offset] > unresolved[rhs.offset]
        }) else { return nil }

        let number = unresolved[best.offset]
        guard let kanji = puzzle.solutionByNumber[number] else { return nil }
        let relatedWords = best.element.2
        let reason: HintExplanation.Reason = relatedWords.count >= 2
            ? .crossingWords
            : (relatedWords.count == 1 ? .constrainedWord : .validatedUniqueSolution)

        return HintExplanation(number: number, kanji: kanji, reason: reason, relatedWords: relatedWords)
    }
}
