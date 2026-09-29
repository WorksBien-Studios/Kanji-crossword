import SwiftUI
import KanjiGameCore

struct ResultsView: View {
    let state: GameState
    let puzzle: Puzzle

    @Environment(\.dismiss) private var dismiss
    @State private var selectedWord: SelectedWord?

    var body: some View {
        NavigationStack {
            List {
                Section("結果") {
                    if state.timerEnabled {
                        LabeledContent("時間", value: durationText(state.elapsedBeforeCurrentRun))
                    }
                    LabeledContent("ヒント", value: "\(state.hintsUsed)回")
                    LabeledContent("確認", value: "\(state.checksUsed)回")
                }

                Section("完成した熟語") {
                    ForEach(Array(puzzle.wordSpans.enumerated()), id: \.offset) { index, span in
                        Button {
                            selectedWord = SelectedWord(index: index, span: span)
                        } label: {
                            HStack {
                                Text(span.word)
                                Spacer()
                                Text(span.reading)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("結果")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedWord) { item in
                WordReadingSheet(span: item.span)
                    .presentationDetents([.medium])
            }
        }
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "0:00"
    }
}

private struct SelectedWord: Identifiable {
    let index: Int
    let span: WordSpan
    var id: Int { index }
}

private struct WordReadingSheet: View {
    let span: WordSpan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("熟語", value: span.word)
                LabeledContent("読み", value: span.reading)
            }
            .navigationTitle("読み方")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}
