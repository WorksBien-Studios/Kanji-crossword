import SwiftUI
import KanjiCommerce
import KanjiPersistence

public struct SettingsView: View {
    let persistence: GamePersistenceStore

    @ObservedObject private var purchaseStore: LifetimePurchaseStore
    @State private var preferences = AppPreferences()
    @State private var loaded = false
    @State private var showTutorial = false
    @State private var showUnlockSheet = false
    @State private var saveError: String?

    public init(
        persistence: GamePersistenceStore,
        purchaseStore: LifetimePurchaseStore
    ) {
        self.persistence = persistence
        self._purchaseStore = ObservedObject(wrappedValue: purchaseStore)
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

            Section("購入") {
                LabeledContent("状態", value: purchaseStatusText)

                if !purchaseStore.hasLifetimeUnlock {
                    Button {
                        showUnlockSheet = true
                    } label: {
                        HStack {
                            Label("全問題を解放", systemImage: "lock.open")
                            Spacer()
                            if let price = purchaseStore.localizedPrice {
                                Text(price)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button {
                    Task {
                        await purchaseStore.restore()
                    }
                } label: {
                    Label("購入を復元", systemImage: "arrow.clockwise")
                }
                .disabled(purchaseStore.isWorking)
            } footer: {
                Text("購入の復元は、以前の買い切り購入が表示されない場合に使用してください。")
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
        .sheet(isPresented: $showUnlockSheet) {
            LifetimeUnlockView(purchaseStore: purchaseStore)
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
        .alert(
            "お知らせ",
            isPresented: Binding(
                get: { purchaseStore.notice != nil },
                set: { if !$0 { purchaseStore.clearMessages() } }
            )
        ) {
            Button("OK") {
                purchaseStore.clearMessages()
            }
        } message: {
            Text(purchaseStore.notice ?? "")
        }
        .alert(
            "購入を確認できません",
            isPresented: Binding(
                get: { purchaseStore.errorMessage != nil && !showUnlockSheet },
                set: { if !$0 { purchaseStore.clearMessages() } }
            )
        ) {
            Button("OK") {
                purchaseStore.clearMessages()
            }
        } message: {
            Text(purchaseStore.errorMessage ?? "")
        }
    }

    private var purchaseStatusText: String {
        switch purchaseStore.state {
        case .checking:
            "確認中"
        case .purchased:
            "購入済み"
        case .offlineCached:
            "購入済み（オフライン）"
        case .pending:
            "承認待ち"
        case .free:
            "無料版"
        case .unavailable:
            "App Storeに接続できません"
        case .verificationFailed:
            "購入情報を検証できません"
        case .failed:
            "確認エラー"
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
