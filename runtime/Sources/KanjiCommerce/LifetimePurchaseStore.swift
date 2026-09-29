#if canImport(StoreKit) && canImport(Combine)
import Combine
import Foundation
import StoreKit

@MainActor
public final class LifetimePurchaseStore: ObservableObject {
    @Published public private(set) var product: Product?
    @Published public private(set) var state: LifetimePurchaseState
    @Published public private(set) var isLoadingProduct = false
    @Published public private(set) var isPurchasing = false
    @Published public private(set) var isRestoring = false
    @Published public private(set) var notice: String?
    @Published public private(set) var errorMessage: String?

    public let productID: String

    private let cache: any LifetimeEntitlementCaching
    private let now: @Sendable () -> Date
    private let productLoader: @Sendable (Set<String>) async throws -> [Product]
    private var cachedSnapshot: LifetimeEntitlementSnapshot?
    private var started = false

    nonisolated(unsafe) private var updatesTask: Task<Void, Never>?

    public init(
        productID: String = LifetimePurchaseConfiguration.productID,
        cache: any LifetimeEntitlementCaching = KeychainLifetimeEntitlementCache(),
        now: @escaping @Sendable () -> Date = Date.init,
        productLoader: @escaping @Sendable (Set<String>) async throws -> [Product] = {
            try await Product.products(for: $0)
        }
    ) {
        self.productID = productID
        self.cache = cache
        self.now = now
        self.productLoader = productLoader

        do {
            if let snapshot = try cache.load(),
               snapshot.isValid(for: productID) {
                cachedSnapshot = snapshot
                state = .offlineCached
            } else {
                state = .checking
            }
        } catch {
            state = .checking
            errorMessage = error.localizedDescription
        }

        updatesTask = Task { @MainActor [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled, let self else { return }
                await self.handleTransactionUpdate(result)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    public var hasLifetimeUnlock: Bool {
        state.hasAccess
    }

    public var localizedPrice: String? {
        product?.displayPrice
    }

    public var isWorking: Bool {
        isLoadingProduct || isPurchasing || isRestoring
    }

    public func start() async {
        if started {
            await refreshEntitlements(authoritativeAbsence: false)
            return
        }
        started = true

        await refreshEntitlements(authoritativeAbsence: false)
        let productLoaded = await loadProduct()
        await refreshEntitlements(authoritativeAbsence: productLoaded)
    }

    public func retryProduct() async {
        guard !isWorking else { return }
        clearMessages()
        let productLoaded = await loadProduct()
        await refreshEntitlements(authoritativeAbsence: productLoaded)
    }

    public func refresh() async {
        await refreshEntitlements(authoritativeAbsence: false)
    }

    public func purchase() async {
        guard !isWorking, !hasLifetimeUnlock else { return }
        clearMessages()

        if product == nil {
            _ = await loadProduct()
        }
        guard let product else {
            state = .unavailable
            errorMessage = "App Storeから購入情報を取得できませんでした。通信状態を確認して、もう一度お試しください。"
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                await consumePurchaseResult(verification)
            case .pending:
                state = .pending
                notice = "購入は保留中です。承認されると自動的に全問題が使えるようになります。"
            case .userCancelled:
                await refreshEntitlements(authoritativeAbsence: false)
            @unknown default:
                state = .failed("unknown_purchase_result")
                errorMessage = "購入結果を確認できませんでした。"
            }
        } catch {
            state = .failed(String(describing: error))
            errorMessage = error.localizedDescription
        }
    }

    public func restore() async {
        guard !isWorking else { return }
        clearMessages()
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements(authoritativeAbsence: true)
            if hasLifetimeUnlock {
                notice = "購入を復元しました。"
            } else {
                notice = "復元できる購入はありませんでした。"
            }
        } catch {
            state = .failed(String(describing: error))
            errorMessage = error.localizedDescription
        }
    }

    public func clearMessages() {
        notice = nil
        errorMessage = nil
    }

    private func loadProduct() async -> Bool {
        isLoadingProduct = true
        defer { isLoadingProduct = false }

        do {
            let products = try await productLoader([productID])
            guard let matching = products.first(where: {
                $0.id == productID && $0.type == .nonConsumable
            }) else {
                product = nil
                if !hasLifetimeUnlock {
                    state = .unavailable
                }
                return false
            }
            product = matching
            return true
        } catch {
            product = nil
            if !hasLifetimeUnlock {
                state = .unavailable
            }
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func refreshEntitlements(authoritativeAbsence: Bool) async {
        var sawTargetUnverified = false

        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                guard transaction.productID == productID,
                      transaction.productType == .nonConsumable else {
                    continue
                }

                if transaction.revocationDate != nil {
                    denyAccessAndClearCache()
                    return
                }

                _ = persistVerifiedEntitlement(transaction)
                return

            case .unverified(let transaction, _):
                guard transaction.productID == productID else { continue }
                sawTargetUnverified = true
            }
        }

        if sawTargetUnverified {
            state = .verificationFailed
            errorMessage = "App Storeの購入情報を検証できませんでした。"
            return
        }

        if authoritativeAbsence {
            denyAccessAndClearCache()
        } else if let cachedSnapshot,
                  cachedSnapshot.isValid(for: productID) {
            state = .offlineCached
        } else {
            state = .free
        }
    }

    private func consumePurchaseResult(
        _ result: VerificationResult<Transaction>
    ) async {
        switch result {
        case .verified(let transaction):
            guard transaction.productID == productID,
                  transaction.productType == .nonConsumable,
                  transaction.revocationDate == nil else {
                state = .verificationFailed
                errorMessage = "購入内容がこのアプリの買い切り商品と一致しませんでした。"
                return
            }

            let persisted = persistVerifiedEntitlement(transaction)
            if persisted {
                await transaction.finish()
            }

        case .unverified:
            state = .verificationFailed
            errorMessage = "App Storeの購入情報を検証できませんでした。"
        }
    }

    private func handleTransactionUpdate(
        _ result: VerificationResult<Transaction>
    ) async {
        switch result {
        case .verified(let transaction):
            guard transaction.productID == productID,
                  transaction.productType == .nonConsumable else {
                return
            }

            if transaction.revocationDate != nil {
                denyAccessAndClearCache()
                notice = "購入が取り消されたため、買い切り機能を無効にしました。"
                await transaction.finish()
                return
            }

            let persisted = persistVerifiedEntitlement(transaction)
            if persisted {
                await transaction.finish()
            }

        case .unverified(let transaction, _):
            guard transaction.productID == productID else { return }
            state = .verificationFailed
            errorMessage = "更新された購入情報を検証できませんでした。"
        }
    }

    @discardableResult
    private func persistVerifiedEntitlement(_ transaction: Transaction) -> Bool {
        let snapshot = LifetimeEntitlementSnapshot(
            productID: transaction.productID,
            transactionID: transaction.id,
            originalTransactionID: transaction.originalID,
            purchaseDate: transaction.purchaseDate,
            verifiedAt: now()
        )

        state = .purchased
        cachedSnapshot = snapshot

        do {
            try cache.save(snapshot)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "購入は確認できましたが、オフライン用の購入情報を保存できませんでした。次回起動時に再確認します。"
            return false
        }
    }

    private func denyAccessAndClearCache() {
        state = .free
        cachedSnapshot = nil
        do {
            try cache.clear()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
