import SwiftUI
import KanjiCommerce
import KanjiGameCore
import KanjiPersistence

/// Inline message shown above the board. It replaces system alerts so the
/// board is never covered while the player reads a hint or a check result.
struct GameBanner: Equatable {
    enum Kind { case info, success, warning }

    let kind: Kind
    let text: String
}

struct GameView: View {
    @ObservedObject var model: GameSessionViewModel
    let persistence: GamePersistenceStore
    @ObservedObject var purchaseStore: LifetimePurchaseStore
    var onBackToList: () -> Void = {}
    var onNextPuzzle: (() -> Void)?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showRestartConfirmation = false
    @State private var showResults = false
    @State private var showCompletionActions = true
    @State private var showKeyboardEntry = false
    @State private var showUnlockSheet = false
    @State private var pendingUnlockAfterResults = false
    @State private var pausedForSceneTransition = false
    @State private var completionCount = 0
    @State private var banner: GameBanner?
    @State private var flagged: Set<Int> = []

    var body: some View {
        lifecycle
    }

    // The modifier chain is split into three pieces so the type checker
    // can resolve each one in reasonable time.
    private var chrome: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 720
            ZStack {
                if wide {
                    wideLayout
                } else {
                    compactLayout
                }

                if model.state.status == .paused {
                    pausedOverlay
                }
            }
        }
        .background(KanjiTheme.canvas)
        .navigationTitle(model.puzzle.difficulty.japaneseTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(
            horizontalSizeClass == .compact ? .hidden : .automatic,
            for: .tabBar
        )
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if model.state.status == .active {
                    Button("休む") {
                        pausedForSceneTransition = false
                        model.send(.pause)
                    }
                    .fontWeight(.bold)
                }

                Menu("その他", systemImage: "ellipsis.circle") {
                    if model.puzzle.difficulty == .expert {
                        Button("キーボード入力", systemImage: "keyboard") {
                            showKeyboardEntry = true
                        }
                        .disabled(
                            model.state.status != .active
                            || model.state.selectedNumber == nil
                        )
                    }

                    if model.state.status == .completed {
                        Button("結果を見る", systemImage: "chart.bar") {
                            showResults = true
                        }
                    }

                    Button("最初から", systemImage: "arrow.counterclockwise", role: .destructive) {
                        showRestartConfirmation = true
                    }
                    .disabled(model.state.status == .completed)
                }
            }
        }
    }

    private var presented: some View {
        chrome
        .confirmationDialog(
            "最初からやり直しますか？",
            isPresented: $showRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("最初からやり直す", role: .destructive) {
                banner = nil
                flagged = []
                model.send(.restartConfirmed)
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("現在の入力は消えます。")
        }
        .sheet(isPresented: $showResults) {
            ResultsView(
                state: model.state,
                puzzle: model.puzzle,
                showUnlockCard: completionCount >= 5 && !purchaseStore.hasLifetimeUnlock,
                localizedPrice: purchaseStore.localizedPrice,
                onUnlockRequested: {
                    pendingUnlockAfterResults = true
                    showResults = false
                }
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showKeyboardEntry) {
            KeyboardEntrySheet(allowedKanji: Set(model.puzzle.traySeed)) { kanji in
                model.send(.enterKanji(kanji))
                showKeyboardEntry = false
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showUnlockSheet) {
            LifetimeUnlockView(purchaseStore: purchaseStore)
        }
        .alert(
            "保存できません",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.clearError() } }
            )
        ) {
            Button("OK") {
                model.clearError()
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var lifecycle: some View {
        presented
        .task {
            await refreshCompletionCount()
        }
        .onChange(of: showResults) { _, isPresented in
            if !isPresented && pendingUnlockAfterResults {
                pendingUnlockAfterResults = false
                showUnlockSheet = true
            }
        }
        .onChange(of: model.lastEvent) { _, event in
            consume(event)
        }
        .onChange(of: model.state.entries) { _, entries in
            // A flagged square stops being flagged as soon as it is corrected.
            flagged = flagged.filter { number in
                guard let value = entries[number] else { return false }
                return value != model.puzzle.solutionByNumber[number]
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                if pausedForSceneTransition && model.state.status == .paused {
                    pausedForSceneTransition = false
                    model.send(.resume)
                }
            case .inactive, .background:
                if model.state.status == .active {
                    pausedForSceneTransition = true
                    model.send(.pause)
                }
            @unknown default:
                break
            }
        }
        .sensoryFeedback(.success, trigger: model.state.status) { old, new in
            model.preferences.hapticsEnabled
                && old != .completed
                && new == .completed
        }
    }

    // MARK: Layouts

    /// iPhone and narrow panes: strip, board, then actions and tiles.
    private var compactLayout: some View {
        VStack(spacing: 0) {
            GameStripView(
                model: model,
                banner: banner,
                onDismissBanner: dismissBanner
            )
            GameBoardView(model: model, flagged: flagged)
            bottomPanel(trayColumns: 5, gridActions: false)
        }
    }

    /// iPad and wide panes: the board in the middle and a side panel holding
    /// the words, actions and tiles so hands never cover the board.
    private var wideLayout: some View {
        HStack(spacing: 0) {
            GameBoardView(model: model, flagged: flagged)
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    GameStripView(
                        model: model,
                        banner: banner,
                        onDismissBanner: dismissBanner,
                        wrapsChips: true
                    )
                    bottomPanel(trayColumns: 4, gridActions: true)
                }
                .padding(.vertical, 14)
            }
            .frame(width: 320)
            .background(KanjiTheme.bar)
        }
    }

    @ViewBuilder
    private func bottomPanel(trayColumns: Int, gridActions: Bool) -> some View {
        switch model.state.status {
        case .active:
            VStack(spacing: 4) {
                GameActionBar(
                    model: model,
                    grid: gridActions,
                    onHint: { model.send(.requestHint) },
                    onCheck: { model.send(.checkMistakes) }
                )
                AnswerTrayView(model: model, columnCount: trayColumns)
            }
            .padding(.top, gridActions ? 0 : 4)
            .background(gridActions ? Color.clear : KanjiTheme.bar)
        case .paused:
            Button("再開する", systemImage: "play.fill") {
                pausedForSceneTransition = false
                model.send(.resume)
            }
            .buttonStyle(KanjiPrimaryButtonStyle())
            .padding()
            .background(gridActions ? Color.clear : KanjiTheme.bar)
        case .completed:
            CompletionPanel(
                showActions: showCompletionActions,
                viewBoard: { showCompletionActions = false },
                viewResults: { showResults = true },
                backToList: onBackToList,
                nextPuzzle: onNextPuzzle
            )
            .background(gridActions ? Color.clear : KanjiTheme.bar)
        }
    }

    private var pausedOverlay: some View {
        VStack(spacing: 16) {
            Text("一時停止中")
                .font(.system(size: 28, weight: .bold, design: .serif))
            Text("盤面は隠しています。用意ができたら再開してください。")
                .foregroundStyle(KanjiTheme.inkSecondary)
                .multilineTextAlignment(.center)
            Button("再開する") {
                pausedForSceneTransition = false
                model.send(.resume)
            }
            .buttonStyle(KanjiPrimaryButtonStyle())
            .frame(maxWidth: 280)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KanjiTheme.canvas)
    }

    // MARK: Events

    private func dismissBanner() {
        banner = nil
        flagged = []
    }

    private func consume(_ event: GameEvent) {
        switch event {
        case .none:
            break
        case .completed:
            banner = nil
            flagged = []
            Task {
                await refreshCompletionCount()
            }
        case .mistakes(let numbers):
            flagged = Set(numbers)
            if numbers.isEmpty {
                banner = GameBanner(
                    kind: .success,
                    text: "間違いはありません。今の入力はすべて合っています。"
                )
            } else {
                banner = GameBanner(
                    kind: .warning,
                    text: "見直す番号: " + numbers.map(String.init).joined(separator: "、")
                        + "。点線のマスです。入力は消していません。"
                )
            }
        case .hint(let hint):
            switch hint.reason {
            case .crossingWords:
                banner = GameBanner(
                    kind: .info,
                    text: "交差する熟語から、番号\(hint.number)は「\(hint.kanji)」です。"
                )
            case .constrainedWord:
                banner = GameBanner(
                    kind: .info,
                    text: "この熟語の条件から、番号\(hint.number)は「\(hint.kanji)」です。"
                )
            case .validatedUniqueSolution:
                banner = GameBanner(
                    kind: .info,
                    text: "唯一の解から、番号\(hint.number)は「\(hint.kanji)」です。"
                )
            }
        }
        model.clearTransientEvent()
    }

    @MainActor
    private func refreshCompletionCount() async {
        completionCount = (try? await persistence.completionHistory().count) ?? 0
    }
}

// MARK: - Strip

/// Sits above the board. Shows a banner when there is one, otherwise the words
/// the selected square belongs to, with what has been entered so far.
struct GameStripView: View {
    @ObservedObject var model: GameSessionViewModel
    let banner: GameBanner?
    let onDismissBanner: () -> Void
    var wrapsChips = false

    var body: some View {
        Group {
            if model.state.status == .completed {
                message(
                    GameBanner(
                        kind: .success,
                        text: "完成しました。盤面はこのまま見られます。"
                    ),
                    dismissable: false
                )
            } else if let banner {
                message(banner, dismissable: true)
            } else if let selected = model.state.selectedNumber {
                wordStrip(selected: selected)
            } else {
                Text("マスを選ぶと、つながる熟語が出ます。")
                    .font(.body)
                    .foregroundStyle(KanjiTheme.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(minHeight: 56)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func message(_ banner: GameBanner, dismissable: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon(banner.kind))
                .foregroundStyle(tint(banner.kind))
                .accessibilityHidden(true)
            Text(banner.text)
                .font(.subheadline)
                .foregroundStyle(KanjiTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            if dismissable {
                Button("とじる", action: onDismissBanner)
                    .font(.subheadline.bold())
                    .foregroundStyle(KanjiTheme.accentText)
                    .frame(minWidth: 56, minHeight: 44)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(background(banner.kind))
        )
    }

    @ViewBuilder
    private func wordStrip(selected: Int) -> some View {
        let insights = BoardInsights(puzzle: model.puzzle)
        let words = insights.words(containing: selected)
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text("番号 \(selected)")
                Text("\(words.count)語")
            }
            .font(.footnote.bold())
            .foregroundStyle(KanjiTheme.inkSecondary)

            if wrapsChips {
                FlowRow(spacing: 8) {
                    ForEach(Array(words.enumerated()), id: \.offset) { _, span in
                        WordChip(
                            slots: insights.slots(for: span, entries: model.state.entries),
                            selected: selected
                        )
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(words.enumerated()), id: \.offset) { _, span in
                            WordChip(
                                slots: insights.slots(for: span, entries: model.state.entries),
                                selected: selected
                            )
                        }
                    }
                }
            }
        }
    }

    private func icon(_ kind: GameBanner.Kind) -> String {
        switch kind {
        case .info: "lightbulb"
        case .success: "checkmark.circle.fill"
        case .warning: "questionmark.circle"
        }
    }

    private func tint(_ kind: GameBanner.Kind) -> Color {
        switch kind {
        case .info: KanjiTheme.accentText
        case .success: KanjiTheme.success
        case .warning: KanjiTheme.stamp
        }
    }

    private func background(_ kind: GameBanner.Kind) -> Color {
        switch kind {
        case .info: KanjiTheme.related
        case .success: KanjiTheme.successTint
        case .warning: KanjiTheme.stampTint
        }
    }
}

private struct WordChip: View {
    let slots: [WordSlot]
    let selected: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                Text(slot.kanji ?? "")
                    .font(KanjiTheme.kanjiFont(size: 19))
                    .foregroundStyle(KanjiTheme.ink)
                    .frame(width: 30, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(slot.number == selected ? KanjiTheme.mark : KanjiTheme.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(
                                slot.number == selected ? KanjiTheme.accent : KanjiTheme.line,
                                lineWidth: slot.number == selected ? 3 : 1.5
                            )
                    )
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(KanjiTheme.fill)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "熟語 " + slots.map { $0.kanji ?? "空欄" }.joined(separator: "、")
        )
    }
}

/// Wraps children onto new lines, so word chips never need horizontal scroll
/// in the iPad side panel.
private struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return CGSize(width: proposal.width ?? maxX, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Actions

/// Five labelled controls. Replaces the icon-only toolbar and the ellipsis
/// menu that used to hide undo, hint and check.
struct GameActionBar: View {
    @ObservedObject var model: GameSessionViewModel
    let grid: Bool
    let onHint: () -> Void
    let onCheck: () -> Void

    var body: some View {
        let active = model.state.status == .active
        let items = LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: grid ? 8 : 0),
                count: grid ? 3 : 5
            ),
            spacing: 8
        ) {
            Button {
                model.send(.undo)
            } label: {
                actionLabel("元に戻す", "arrow.uturn.backward")
            }
            .disabled(!active || model.state.undoStack.isEmpty)

            Button {
                model.send(.redo)
            } label: {
                actionLabel("やり直す", "arrow.uturn.forward")
            }
            .disabled(!active || model.state.redoStack.isEmpty)

            Button(action: onHint) {
                actionLabel("ヒント", "lightbulb")
            }
            .disabled(!active)

            Button(action: onCheck) {
                actionLabel("確認", "checkmark.circle")
            }
            .disabled(!active)

            Button {
                model.send(.eraseSelected)
            } label: {
                actionLabel("消す", "delete.left")
            }
            .disabled(!canErase)
        }
        .buttonStyle(KanjiActionButtonStyle(bordered: grid))

        items
            .padding(.horizontal, grid ? 16 : 8)
    }

    private func actionLabel(_ title: String, _ systemImage: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .font(.title3)
            Text(title)
        }
    }

    private var canErase: Bool {
        guard model.state.status == .active,
              let number = model.state.selectedNumber else { return false }
        return model.puzzle.startersByNumber[number] == nil
            && model.state.entries[number] != nil
    }
}

private struct CompletionPanel: View {
    let showActions: Bool
    let viewBoard: () -> Void
    let viewResults: () -> Void
    let backToList: () -> Void
    let nextPuzzle: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            if showActions {
                Button("結果を見る", action: viewResults)
                    .buttonStyle(KanjiPrimaryButtonStyle())
                HStack(spacing: 10) {
                    Button("完成盤を見る", action: viewBoard)
                        .buttonStyle(KanjiSecondaryButtonStyle(compact: true))
                    if let nextPuzzle {
                        Button("次の問題", action: nextPuzzle)
                            .buttonStyle(KanjiSecondaryButtonStyle(compact: true))
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Button("結果を見る", action: viewResults)
                        .buttonStyle(KanjiPrimaryButtonStyle(compact: true))
                    if let nextPuzzle {
                        Button("次の問題", action: nextPuzzle)
                            .buttonStyle(KanjiSecondaryButtonStyle(compact: true))
                    }
                }
            }
            Button("問題一覧へ", action: backToList)
                .font(.body.bold())
                .foregroundStyle(KanjiTheme.accentText)
                .frame(minHeight: 44)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Keyboard entry (達人)

private struct KeyboardEntrySheet: View {
    let allowedKanji: Set<String>
    let submit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("漢字1文字", text: $text)
                        .multilineTextAlignment(.center)
                        .font(.largeTitle)
                        .focused($focused)
                } footer: {
                    Text("候補にある漢字を1文字入力してください。")
                }
            }
            .navigationTitle("キーボード入力")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("入力") {
                        submit(text)
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                focused = true
            }
        }
    }

    private var isValid: Bool {
        text.count == 1 && allowedKanji.contains(text)
    }
}
