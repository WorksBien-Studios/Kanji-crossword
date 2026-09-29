import SwiftUI
import KanjiGameCore

/// Large kanji tiles. A tile dims once its kanji is on the board, so the
/// remaining choices are visible at a glance.
struct AnswerTrayView: View {
    @ObservedObject var model: GameSessionViewModel
    var columnCount = 5

    var body: some View {
        let used = Set(model.state.entries.values)
        let height = 54 * CGFloat(model.preferences.textScale)

        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 8),
                count: columnCount
            ),
            spacing: 8
        ) {
            ForEach(Array(model.puzzle.traySeed.enumerated()), id: \.offset) { _, kanji in
                Button {
                    model.send(.enterKanji(kanji))
                } label: {
                    Text(kanji)
                }
                .buttonStyle(
                    KanjiTileButtonStyle(used: used.contains(kanji), height: height)
                )
                .disabled(
                    model.state.selectedNumber == nil
                    || model.state.status != .active
                )
                .accessibilityLabel("漢字 \(kanji) を入力")
                .accessibilityValue(used.contains(kanji) ? "盤面に入力済み" : "")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
