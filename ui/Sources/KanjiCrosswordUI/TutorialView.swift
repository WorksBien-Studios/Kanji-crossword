import SwiftUI

public struct TutorialView: View {
    private let onStart: () -> Void

    @State private var page = 0
    @State private var selectedNumber = false
    @State private var sampleKanji: String?

    public init(onStart: @escaping () -> Void) {
        self.onStart = onStart
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TabView(selection: $page) {
                    VStack(spacing: 24) {
                        tutorialHeading(
                            "1. 番号のマスをタップ",
                            detail: "同じ番号のマスがまとめて選ばれます。"
                        )
                        MiniBoard(
                            selected: selectedNumber,
                            kanji: nil
                        ) {
                            selectedNumber = true
                        }
                    }
                    .tag(0)

                    VStack(spacing: 24) {
                        tutorialHeading(
                            "2. 漢字を選ぶ",
                            detail: "候補の漢字をタップしてください。"
                        )
                        MiniBoard(selected: true, kanji: nil) {}
                        HStack {
                            ForEach(["日", "本", "語"], id: \.self) { kanji in
                                Button(kanji) {
                                    sampleKanji = kanji
                                    withAnimation {
                                        page = 2
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }
                    }
                    .tag(1)

                    VStack(spacing: 24) {
                        tutorialHeading(
                            "3. 同じ番号にまとめて入ります",
                            detail: "あとは同じように盤面を埋めていくだけです。"
                        )
                        MiniBoard(
                            selected: true,
                            kanji: sampleKanji ?? "日"
                        ) {}
                        Label("間違えても「元に戻す」で戻せます", systemImage: "arrow.uturn.backward.circle")
                            .foregroundStyle(.secondary)
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))

                Button(page == 2 ? "今すぐ始める" : "次へ") {
                    if page == 2 {
                        onStart()
                    } else {
                        withAnimation {
                            page += 1
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(page == 0 && !selectedNumber)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("遊び方")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func tutorialHeading(_ title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(detail)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
}

private struct MiniBoard: View {
    let selected: Bool
    let kanji: String?
    let action: () -> Void

    var body: some View {
        Grid(horizontalSpacing: 2, verticalSpacing: 2) {
            GridRow {
                MiniCell(number: 1, selected: selected, kanji: kanji, action: action)
                MiniCell(number: 2, selected: false, kanji: "本", action: {})
            }
            GridRow {
                MiniCell(number: 1, selected: selected, kanji: kanji, action: action)
                Rectangle()
                    .fill(.primary)
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct MiniCell: View {
    let number: Int
    let selected: Bool
    let kanji: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(selected ? Color.accentColor.opacity(0.16) : .clear)
                Rectangle()
                    .strokeBorder(
                        selected ? Color.accentColor : Color.secondary.opacity(0.45),
                        lineWidth: selected ? 3 : 1
                    )
                Text(String(number))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(4)
                if let kanji {
                    Text(kanji)
                        .font(.title)
                }
            }
            .frame(width: 72, height: 72)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            kanji.map { "番号 \(number)、\($0)" } ?? "番号 \(number)、空欄"
        )
    }
}
