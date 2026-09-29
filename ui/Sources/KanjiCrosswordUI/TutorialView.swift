import SwiftUI

public struct TutorialView: View {
    private let onStart: () -> Void
    @State private var page = 0

    public init(onStart: @escaping () -> Void) {
        self.onStart = onStart
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TabView(selection: $page) {
                    TutorialPage(
                        systemImage: "hand.tap",
                        title: "番号のマスをタップ",
                        text: "同じ番号のマスがまとめて選ばれます。"
                    )
                    .tag(0)

                    TutorialPage(
                        systemImage: "character.cursor.ibeam",
                        title: "漢字を選ぶ",
                        text: "下の候補から漢字をタップすると、同じ番号へまとめて入ります。"
                    )
                    .tag(1)

                    TutorialPage(
                        systemImage: "arrow.uturn.backward.circle",
                        title: "いつでも元に戻せます",
                        text: "間違えても大丈夫。元に戻す、やり直す、ヒントをいつでも使えます。"
                    )
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
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("遊び方")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct TutorialPage: View {
    let systemImage: String
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 64, weight: .regular))
                .accessibilityHidden(true)

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(text)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}
