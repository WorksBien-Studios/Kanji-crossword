import SwiftUI
import KanjiGameCore

struct AnswerTrayView: View {
    @ObservedObject var model: GameSessionViewModel

    private var columns: [GridItem] {
        let minimum = 48 * model.preferences.textScale
        let maximum = 72 * model.preferences.textScale
        return [
            GridItem(.adaptive(minimum: minimum, maximum: maximum), spacing: 8)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let selected = model.state.selectedNumber {
                Text("番号 \(selected)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("マスを選んでください")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(model.puzzle.traySeed.enumerated()), id: \.offset) { _, kanji in
                    Button(kanji) {
                        model.send(.enterKanji(kanji))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .font(.body.weight(.medium))
                    .disabled(model.state.selectedNumber == nil)
                    .accessibilityLabel("漢字 \(kanji) を入力")
                }
            }
        }
        .padding()
        .background(.bar)
    }
}
