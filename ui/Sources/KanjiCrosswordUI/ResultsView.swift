import SwiftUI
import KanjiGameCore

struct ResultsView: View {
    let state: GameState
    let puzzle: Puzzle
    let personalBest: TimeInterval?
    let showUnlockCard: Bool
    let localizedPrice: String?
    let onUnlockRequested: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedWordIndex = 0

    init(
        state: GameState,
        puzzle: Puzzle,
        personalBest: TimeInterval? = nil,
        showUnlockCard: Bool = false,
        localizedPrice: String? = nil,
        onUnlockRequested: (() -> Void)? = nil
    ) {
        self.state = state
        self.puzzle = puzzle
        self.personalBest = personalBest
        self.showUnlockCard = showUnlockCard
        self.localizedPrice = localizedPrice
        self.onUnlockRequested = onUnlockRequested
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    statsRow
                    Label("完成盤は「記録」に保存されました", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(KanjiTheme.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let span = selectedSpan {
                        reviewCard(span)
                    }
                    wordsSection
                    if showUnlockCard, let onUnlockRequested {
                        unlockCard(onUnlockRequested)
                    }
                }
                .padding(16)
            }
            .background(KanjiTheme.canvas)
            .navigationTitle("結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var selectedSpan: WordSpan? {
        guard puzzle.wordSpans.indices.contains(selectedWordIndex) else {
            return puzzle.wordSpans.first
        }
        return puzzle.wordSpans[selectedWordIndex]
    }

    // MARK: Sections

    private var statsRow: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 120), spacing: 10)],
            spacing: 10
        ) {
            if state.timerEnabled {
                stat("時間", durationText(state.elapsedBeforeCurrentRun))
                if let effectivePersonalBest {
                    stat("自己ベスト", durationText(effectivePersonalBest))
                }
            }
            stat("修正", "\(ResultMetrics.correctionCount(state: state, puzzle: puzzle))回")
            stat("ヒント", "\(state.hintsUsed)回")
            stat("間違い確認", "\(state.checksUsed)回")
        }
    }

    private var effectivePersonalBest: TimeInterval? {
        guard state.timerEnabled, state.elapsedBeforeCurrentRun > 0 else { return nil }
        guard let personalBest else { return state.elapsedBeforeCurrentRun }
        return min(personalBest, state.elapsedBeforeCurrentRun)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(KanjiTheme.inkSecondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(KanjiTheme.ink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(KanjiTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(KanjiTheme.line, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    /// The finished board with the chosen word lit up, and its reading.
    private func reviewCard(_ span: WordSpan) -> some View {
        KanjiCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 18) {
                    board(span)
                    reading(span)
                }
                VStack(alignment: .leading, spacing: 12) {
                    board(span)
                    reading(span)
                }
            }
        }
    }

    private func board(_ span: WordSpan) -> some View {
        MiniBoardView(
            puzzle: puzzle,
            cellSize: puzzle.columns > 10 ? 20 : 26,
            style: .solved,
            highlighted: BoardInsights(puzzle: puzzle).cellKeys(of: span)
        )
    }

    private func reading(_ span: WordSpan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(span.word)
                .font(.system(size: 44, weight: .heavy, design: .serif))
                .foregroundStyle(KanjiTheme.ink)
            Text(span.reading)
                .font(.title3.bold())
                .foregroundStyle(KanjiTheme.accentText)
            Text("タップした熟語のマスが黄色になります。")
                .font(.footnote)
                .foregroundStyle(KanjiTheme.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("完成した熟語（\(puzzle.wordSpans.count)語）")
                .font(.subheadline.bold())
                .foregroundStyle(KanjiTheme.inkSecondary)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150), spacing: 8)],
                spacing: 8
            ) {
                ForEach(Array(puzzle.wordSpans.enumerated()), id: \.offset) { index, span in
                    Button {
                        selectedWordIndex = index
                    } label: {
                        HStack {
                            Text(span.word)
                                .font(.system(size: 22, weight: .heavy, design: .serif))
                                .foregroundStyle(KanjiTheme.ink)
                            Spacer(minLength: 4)
                            Text(span.reading)
                                .font(.footnote)
                                .foregroundStyle(KanjiTheme.inkSecondary)
                        }
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(index == selectedWordIndex ? KanjiTheme.mark : KanjiTheme.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    index == selectedWordIndex ? KanjiTheme.accent : KanjiTheme.line,
                                    lineWidth: index == selectedWordIndex ? 3 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(span.word)、\(span.reading)")
                    .accessibilityAddTraits(index == selectedWordIndex ? [.isSelected] : [])
                }
            }
        }
    }

    /// Informational, never modal: the purchase sheet opens only on a tap.
    private func unlockCard(_ onUnlockRequested: @escaping () -> Void) -> some View {
        KanjiCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("続きも、広告なしで。")
                    .font(.headline)
                    .foregroundStyle(KanjiTheme.ink)
                Text("無料で遊べるのは30問までです。買い切り版なら、残りの問題もすべて遊べます。")
                    .font(.subheadline)
                    .foregroundStyle(KanjiTheme.inkSecondary)
                Button {
                    onUnlockRequested()
                } label: {
                    HStack {
                        Text("全問題を解放")
                        Spacer()
                        if let localizedPrice {
                            Text(localizedPrice)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .buttonStyle(KanjiSecondaryButtonStyle(compact: true))
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
