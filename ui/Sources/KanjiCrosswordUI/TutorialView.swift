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
                            detail: "選んだマスが黄色になります。同じ番号のマスがあれば、いっしょに光ります。"
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
                            detail: "下の大きな漢字をひとつ押すだけ。ドラッグは、いりません。"
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
                                .buttonStyle(KanjiTileButtonStyle())
                                .frame(width: 72)
                            }
                        }
                    }
                    .tag(1)

                    VStack(spacing: 24) {
                        tutorialHeading(
                            "3. つながる熟語が完成します",
                            detail: "間違えても、ほかの入力は消えません。解き終わっても、盤面はそのまま残ります。"
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
                .scrollDisabled(true)

                Button(page == 2 ? "今すぐ始める" : "次へ") {
                    if page == 2 {
                        onStart()
                    } else {
                        withAnimation {
                            page += 1
                        }
                    }
                }
                .buttonStyle(KanjiPrimaryButtonStyle())
                .disabled(
                    (page == 0 && !selectedNumber)
                    || (page == 1 && sampleKanji == nil)
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(KanjiTheme.canvas)
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
                Color.clear
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? KanjiTheme.mark : KanjiTheme.card)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        selected ? KanjiTheme.accent : KanjiTheme.line,
                        lineWidth: selected ? 4 : 1.5
                    )
                Text(String(number))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(4)
                if let kanji {
                    Text(kanji)
                        .font(KanjiTheme.kanjiFont(size: 36))
                        .foregroundStyle(KanjiTheme.ink)
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
