import SwiftUI
import KanjiCommerce

public struct LifetimeUnlockView: View {
    @ObservedObject private var purchaseStore: LifetimePurchaseStore
    @Environment(\.dismiss) private var dismiss

    public init(purchaseStore: LifetimePurchaseStore) {
        self.purchaseStore = purchaseStore
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("全360問、すべてのモードと難易度", systemImage: "square.grid.3x3")
                        Label("購入後はオフラインでも遊べます", systemImage: "wifi.slash")
                        Label("広告、コイン、回数制限はありません", systemImage: "checkmark.seal")
                            .fontWeight(.bold)
                    }
                    .font(.body)
                } header: {
                    Text("一度のお支払いで、ずっと")
                } footer: {
                    Text("無料の30問は、これからもそのまま遊べます。")
                }

                Section {
                    switch purchaseStore.state {
                    case .purchased:
                        Label("購入済み", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.secondary)
                    case .offlineCached:
                        Label("購入済み（オフライン確認）", systemImage: "checkmark.seal")
                            .foregroundStyle(.secondary)
                    case .pending:
                        Label("購入の承認待ち", systemImage: "clock")
                            .foregroundStyle(.secondary)
                    default:
                        purchaseControls
                    }
                }

                Section {
                    Button {
                        Task {
                            await purchaseStore.restore()
                        }
                    } label: {
                        Label("購入を復元", systemImage: "arrow.clockwise")
                    }
                    .disabled(purchaseStore.isWorking)
                } footer: {
                    Text("以前に購入したのに反映されていない場合は、「購入を復元」をお使いください。Apple IDの確認が表示されることがあります。")
                }
            }
            .scrollContentBackground(.hidden)
            .background(KanjiTheme.canvas)
            .navigationTitle("全問題を解放")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .task {
                if purchaseStore.product == nil && !purchaseStore.isLoadingProduct {
                    await purchaseStore.start()
                }
            }
            .onChange(of: purchaseStore.hasLifetimeUnlock) { _, unlocked in
                if unlocked {
                    dismiss()
                }
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
                "購入を完了できません",
                isPresented: Binding(
                    get: { purchaseStore.errorMessage != nil },
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
    }

    @ViewBuilder
    private var purchaseControls: some View {
        if purchaseStore.isLoadingProduct {
            HStack {
                ProgressView()
                Text("価格を確認しています")
            }
        } else if let price = purchaseStore.localizedPrice {
            Button {
                Task {
                    await purchaseStore.purchase()
                }
            } label: {
                HStack {
                    Text("買い切りで解放")
                    Spacer()
                    Text(price)
                }
            }
            .disabled(purchaseStore.isWorking)
        } else {
            ContentUnavailableView {
                Label("価格を取得できません", systemImage: "wifi.exclamationmark")
            } actions: {
                Button("もう一度試す") {
                    Task {
                        await purchaseStore.retryProduct()
                    }
                }
                .disabled(purchaseStore.isWorking)
            }
        }
    }
}
