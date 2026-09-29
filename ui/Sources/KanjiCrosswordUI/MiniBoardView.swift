import SwiftUI
import KanjiGameCore

/// A small, non-interactive picture of a board. Used as a thumbnail on the
/// home and records screens and as the word-review board on the results screen.
struct MiniBoardView: View {
    enum Style {
        /// Filled cells are solid; no kanji shown.
        case progress([Int: String])
        /// The finished grid with kanji visible.
        case solved
    }

    let puzzle: Puzzle
    let cellSize: CGFloat
    var style: Style = .solved
    var highlighted: Set<String> = []

    var body: some View {
        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(0..<puzzle.rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<puzzle.columns, id: \.self) { column in
                        cell(row: row, column: column)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("盤面の縮小図")
    }

    private var spacing: CGFloat { cellSize > 16 ? 2 : 1 }

    @ViewBuilder
    private func cell(row: Int, column: Int) -> some View {
        let coordinate = CellCoordinate(row: row, column: column)
        if let number = puzzle.number(at: coordinate),
           puzzle.cellLayout[row][column] == "." {
            let key = coordinate.encoded
            RoundedRectangle(cornerRadius: cellSize > 16 ? 4 : 2, style: .continuous)
                .fill(fill(number: number, key: key))
                .overlay {
                    if case .solved = style, cellSize > 16 {
                        Text(puzzle.solutionByNumber[number] ?? "")
                            .font(KanjiTheme.kanjiFont(size: cellSize * 0.62))
                            .foregroundStyle(KanjiTheme.ink)
                            .minimumScaleFactor(0.5)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: cellSize > 16 ? 4 : 2, style: .continuous)
                        .strokeBorder(
                            highlighted.contains(key) ? KanjiTheme.ink : KanjiTheme.line,
                            lineWidth: highlighted.contains(key) ? 2 : 1
                        )
                )
                .frame(width: cellSize, height: cellSize)
        } else {
            Color.clear.frame(width: cellSize, height: cellSize)
        }
    }

    private func fill(number: Int, key: String) -> Color {
        if highlighted.contains(key) { return KanjiTheme.mark }
        switch style {
        case .solved:
            return KanjiTheme.successTint
        case .progress(let entries):
            if puzzle.startersByNumber[number] != nil { return KanjiTheme.inkSecondary }
            return entries[number] != nil ? KanjiTheme.accent : KanjiTheme.card
        }
    }
}
