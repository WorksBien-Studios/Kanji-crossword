import SwiftUI
import KanjiGameCore

struct GameView: View {
    @ObservedObject var model: GameSessionViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var showRestartConfirmation = false
    @State private var showResults = false
    @State private var showCompletionActions = true
    @State private var showKeyboardEntry = false
    @State private var pausedForSceneTransition = false
    @State private var feedbackTitle: String?
    @State private var feedbackMessage: String?

    var body: some View {
        ZStack {
            GameBoardView(model: model)

            if model.state.status == .paused {
                ContentUnavailableView {
                    Label("一時停止", systemImage: "pause.circle")
                } actions: {
                    Button("再開") {
                        pausedForSceneTransition = false
                        model.send(.resume)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .background(.regularMaterial)
            }
        }
        .navigationTitle(model.puzzle.difficulty.japaneseTitle)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            switch model.state.status {
            case .active:
                AnswerTrayView(model: model)
            case .paused:
                HStack {
                    Button("再開", systemImage: "play") {
                        pausedForSceneTransition = false
                        model.send(.resume)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.bar)
            case .completed:
                if showCompletionActions {
                    CompletionActions(
                        viewBoard: { showCompletionActions = false },
                        viewResults: { showResults = true }
                    )
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("元に戻す", systemImage: "arrow.uturn.backward") {
                    model.send(.undo)
                }
                .disabled(model.state.undoStack.isEmpty || model.state.status != .active)

                Button("やり直す", systemImage: "arrow.uturn.forward") {
                    model.send(.redo)
                }
                .disabled(model.state.redoStack.isEmpty || model.state.status != .active)

                if model.preferences.checkMistakesByDefault {
                    Button("間違いを確認", systemImage: "checkmark.circle") {
                        model.send(.checkMistakes)
                    }
                    .disabled(model.state.status != .active)
                }

                Menu("その他", systemImage: "ellipsis.circle") {
                    Button("消す", systemImage: "delete.left") {
                        model.send(.eraseSelected)
                    }
                    .disabled(!canEraseSelection)

                    if model.puzzle.difficulty == .expert {
                        Button("キーボード入力", systemImage: "keyboard") {
                            showKeyboardEntry = true
                        }
                        .disabled(model.state.status != .active || model.state.selectedNumber == nil)
                    }

                    Button("ヒント", systemImage: "lightbulb") {
                        model.send(.requestHint)
                    }
                    .disabled(model.state.status != .active)

                    if !model.preferences.checkMistakesByDefault {
                        Button("間違いを確認", systemImage: "checkmark.circle") {
                            model.send(.checkMistakes)
                        }
                        .disabled(model.state.status != .active)
                    }

                    if model.state.status == .active {
                        Button("一時停止", systemImage: "pause") {
                            pausedForSceneTransition = false
                            model.send(.pause)
                        }
                    } else if model.state.status == .paused {
                        Button("再開", systemImage: "play") {
                            pausedForSceneTransition = false
                            model.send(.resume)
                        }
                    }

                    if model.state.status == .completed {
                        Button("結果を見る", systemImage: "chart.bar") {
                            showResults = true
                        }
                    }

                    Divider()

                    Button("最初から", systemImage: "arrow.counterclockwise", role: .destructive) {
                        showRestartConfirmation = true
                    }
                    .disabled(model.state.status == .completed)
                }
            }
        }
        .confirmationDialog(
            "最初からやり直しますか？",
            isPresented: $showRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("最初からやり直す", role: .destructive) {
                model.send(.restartConfirmed)
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("現在の入力は消えます。")
        }
        .sheet(isPresented: $showResults) {
            ResultsView(state: model.state, puzzle: model.puzzle)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showKeyboardEntry) {
            KeyboardEntrySheet(allowedKanji: Set(model.puzzle.traySeed)) { kanji in
                model.send(.enterKanji(kanji))
                showKeyboardEntry = false
            }
            .presentationDetents([.medium])
        }
        .alert(
            feedbackTitle ?? "",
            isPresented: Binding(
                get: { feedbackTitle != nil },
                set: { if !$0 { feedbackTitle = nil; feedbackMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let feedbackMessage {
                Text(feedbackMessage)
            }
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
        .onChange(of: model.lastEvent) { _, event in
            consume(event)
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

    private var canEraseSelection: Bool {
        guard model.state.status == .active,
              let number = model.state.selectedNumber else { return false }
        return model.puzzle.startersByNumber[number] == nil
            && model.state.entries[number] != nil
    }

    private func consume(_ event: GameEvent) {
        switch event {
        case .none, .completed:
            break
        case .mistakes(let numbers):
            feedbackTitle = numbers.isEmpty ? "間違いはありません" : "確認しました"
            feedbackMessage = numbers.isEmpty
                ? "今入っている漢字はすべて合っています。"
                : "見直す番号: " + numbers.map(String.init).joined(separator: "、")
        case .hint(let hint):
            feedbackTitle = "ヒント"
            switch hint.reason {
            case .crossingWords:
                feedbackMessage = "交差する言葉から、番号\(hint.number)は「\(hint.kanji)」です。"
            case .constrainedWord:
                feedbackMessage = "この熟語の条件から、番号\(hint.number)は「\(hint.kanji)」です。"
            case .validatedUniqueSolution:
                feedbackMessage = "唯一の解から、番号\(hint.number)は「\(hint.kanji)」です。"
            }
        }
        model.clearTransientEvent()
    }
}

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

private struct CompletionActions: View {
    let viewBoard: () -> Void
    let viewResults: () -> Void

    var body: some View {
        HStack {
            Button("完成盤を見る", action: viewBoard)
                .buttonStyle(.bordered)
            Button("結果を見る", action: viewResults)
                .buttonStyle(.borderedProminent)
        }
        .controlSize(.large)
        .padding()
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}
