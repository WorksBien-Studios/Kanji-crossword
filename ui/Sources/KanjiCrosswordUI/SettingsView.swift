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
            displaySection
            interactionSection
            purchaseSection
            helpSection
            legalSection
        }
        .scrollContentBackground(.hidden)
        .background(KanjiTheme.canvas)
        .navigationTitle("設定")
        .overlay {
            if !loaded {
                ProgressView()
            }
        }
        .task {
            await loadPreferences()
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
            isPresented: saveErrorPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
        .alert(
            "お知らせ",
            isPresented: purchaseNoticePresented
        ) {
            Button("OK") {
                purchaseStore.clearMessages()
            }
        } message: {
            Text(purchaseStore.notice ?? "")
        }
        .alert(
            "購入を確認できません",
            isPresented: purchaseErrorPresented
        ) {
            Button("OK") {
                purchaseStore.clearMessages()
            }
        } message: {
            Text(purchaseStore.errorMessage ?? "")
        }
    }

    private var displaySection: some View {
        Section("表示") {
            TextSizePreview(
                scale: preferences.textScale,
                highContrast: preferences.highContrast
            )

            Picker("文字サイズ", selection: textScaleBinding) {
                Text("標準").tag(1.0)
                Text("大きい").tag(1.25)
                Text("特大").tag(1.5)
            }
            .pickerStyle(.segmented)
            .controlSize(.large)

            Toggle("高コントラスト", isOn: highContrastBinding)
        }
    }

    private var interactionSection: some View {
        Section("操作") {
            Toggle("効果音", isOn: soundBinding)
            Toggle("触覚フィードバック", isOn: hapticsBinding)
            Toggle("タイマーを標準で使う", isOn: timerBinding)
            Toggle("間違い確認を使いやすく表示", isOn: checkBinding)
        }
    }

    @ViewBuilder
    private var purchaseSection: some View {
        Section {
            LabeledContent("状態", value: purchaseStatusText)

            if !purchaseStore.hasLifetimeUnlock {
                Button {
                    showUnlockSheet = true
                } label: {
                    PurchaseRow(price: purchaseStore.localizedPrice)
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
        } header: {
            Text("購入")
        } footer: {
            Text("購入の復元は、以前の買い切り購入が表示されない場合に使用してください。")
        }
    }

    private var helpSection: some View {
        Section("ヘルプ") {
            Button {
                showTutorial = true
            } label: {
                Label("遊び方", systemImage: "questionmark.circle")
            }
        }
    }

    private var legalSection: some View {
        Section("プライバシーと法的情報") {
            Link(destination: KanjiPolicyLinks.privacy) {
                Label("プライバシーポリシー", systemImage: "hand.raised")
            }

            NavigationLink {
                LicensesView()
            } label: {
                Label("ライセンス・第三者表記", systemImage: "doc.text")
            }
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

    private var saveErrorPresented: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )
    }

    private var purchaseNoticePresented: Binding<Bool> {
        Binding(
            get: { purchaseStore.notice != nil },
            set: { if !$0 { purchaseStore.clearMessages() } }
        )
    }

    private var purchaseErrorPresented: Binding<Bool> {
        Binding(
            get: { purchaseStore.errorMessage != nil && !showUnlockSheet },
            set: { if !$0 { purchaseStore.clearMessages() } }
        )
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

    @MainActor
    private func loadPreferences() async {
        do {
            preferences = try await persistence.loadPreferences()
        } catch {
            saveError = String(describing: error)
        }
        loaded = true
    }

    private func binding<Value>(
        _ keyPath: WritableKeyPath<AppPreferences, Value>
    ) -> Binding<Value> {
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

/// Shows a selected square and a sample sentence at the chosen size, so the
/// effect of the setting is visible before leaving the screen.
private struct TextSizePreview: View {
    let scale: Double
    let highContrast: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(KanjiTheme.mark)
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(KanjiTheme.accent, lineWidth: highContrast ? 5 : 4)
                Text("7")
                    .font(.system(size: 12 * scale, weight: .bold))
                    .foregroundStyle(KanjiTheme.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(EdgeInsets(top: 3, leading: 5, bottom: 0, trailing: 0))
                Text("異")
                    .font(KanjiTheme.kanjiFont(size: 28 * scale))
                    .foregroundStyle(KanjiTheme.ink)
            }
            .frame(width: 52 * scale, height: 52 * scale)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("「特異」")
                    .font(.system(size: 17 * scale, weight: .bold))
                Text("この大きさで表示されます。")
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(KanjiTheme.inkSecondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("文字サイズの見本")
    }
}

private struct PurchaseRow: View {
    let price: String?

    var body: some View {
        HStack {
            Label("全問題を解放", systemImage: "lock.open")
            Spacer()
            if let price {
                Text(price)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
