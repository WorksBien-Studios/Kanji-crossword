import SwiftUI
import KanjiPersistence

public struct SettingsView: View {
    let persistence: GamePersistenceStore

    @State private var preferences = AppPreferences()
    @State private var loaded = false
    @State private var showTutorial = false
    @State private var saveError: String?

    public init(persistence: GamePersistenceStore) {
        self.persistence = persistence
    }

    public var body: some View {
        Form {
            Section("表示") {
                Picker("文字サイズ", selection: textScaleBinding) {
                    Text("標準").tag(1.0)
                    Text("大きい").tag(1.25)
                    Text("特大").tag(1.5)
                }

                Toggle("高コントラスト", isOn: highContrastBinding)
            }

            Section("操作") {
                Toggle("効果音", isOn: soundBinding)
                Toggle("触覚フィードバック", isOn: hapticsBinding)
                Toggle("タイマーを標準で使う", isOn: timerBinding)
                Toggle("間違い確認を使いやすく表示", isOn: checkBinding)
            }

            Section("ヘルプ") {
                Button {
                    showTutorial = true
                } label: {
                    Label("遊び方", systemImage: "questionmark.circle")
                }
            }
        }
        .navigationTitle("設定")
        .overlay {
            if !loaded {
                ProgressView()
            }
        }
        .task {
            do {
                preferences = try await persistence.loadPreferences()
                loaded = true
            } catch {
                saveError = String(describing: error)
                loaded = true
            }
        }
        .sheet(isPresented: $showTutorial) {
            TutorialView {
                showTutorial = false
            }
        }
        .alert(
            "設定を保存できません",
            isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private var textScaleBinding: Binding<Double> {
        binding(\.textScale)
    }

    private var highContrastBinding: Binding<Bool> {
        binding(\.highContrast)
    }

    private var soundBinding: Binding<Bool> {
        binding(\.soundEnabled)
    }

    private var hapticsBinding: Binding<Bool> {
        binding(\.hapticsEnabled)
    }

    private var timerBinding: Binding<Bool> {
        binding(\.timerEnabledByDefault)
    }

    private var checkBinding: Binding<Bool> {
        binding(\.checkMistakesByDefault)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { value in
                preferences[keyPath: keyPath] = value
                let snapshot = preferences
                Task {
                    do {
                        try await persistence.savePreferences(snapshot)
                    } catch {
                        await MainActor.run {
                            saveError = String(describing: error)
                        }
                    }
                }
            }
        )
    }
}
