import Foundation
import Testing
@testable import KanjiCommerce

@Suite("Lifetime purchase contracts")
struct LifetimePurchaseTests {
    @Test("only verified access states unlock paid content")
    func accessStates() {
        #expect(LifetimePurchaseState.purchased.hasAccess)
        #expect(LifetimePurchaseState.offlineCached.hasAccess)
        #expect(!LifetimePurchaseState.checking.hasAccess)
        #expect(!LifetimePurchaseState.free.hasAccess)
        #expect(!LifetimePurchaseState.pending.hasAccess)
        #expect(!LifetimePurchaseState.unavailable.hasAccess)
        #expect(!LifetimePurchaseState.verificationFailed.hasAccess)
        #expect(!LifetimePurchaseState.failed("x").hasAccess)
    }

    @Test("snapshot is product-bound and versioned")
    func snapshotValidation() {
        let snapshot = LifetimeEntitlementSnapshot(
            productID: LifetimePurchaseConfiguration.productID,
            transactionID: 10,
            originalTransactionID: 9,
            purchaseDate: Date(timeIntervalSince1970: 100),
            verifiedAt: Date(timeIntervalSince1970: 200)
        )

        #expect(snapshot.isValid(for: LifetimePurchaseConfiguration.productID))
        #expect(!snapshot.isValid(for: "different.product"))

        let stale = LifetimeEntitlementSnapshot(
            schemaVersion: 99,
            productID: LifetimePurchaseConfiguration.productID,
            transactionID: 10,
            originalTransactionID: 9,
            purchaseDate: Date(timeIntervalSince1970: 100),
            verifiedAt: Date(timeIntervalSince1970: 200)
        )
        #expect(!stale.isValid(for: LifetimePurchaseConfiguration.productID))
    }

    @Test("zero transaction identifiers are rejected")
    func rejectsZeroIdentifiers() {
        let snapshot = LifetimeEntitlementSnapshot(
            productID: LifetimePurchaseConfiguration.productID,
            transactionID: 0,
            originalTransactionID: 1,
            purchaseDate: .distantPast,
            verifiedAt: .distantPast
        )
        #expect(!snapshot.isValid(for: LifetimePurchaseConfiguration.productID))
    }
}
