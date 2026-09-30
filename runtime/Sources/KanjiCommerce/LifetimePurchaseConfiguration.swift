import Foundation

public enum LifetimePurchaseConfiguration {
    public static let productID = "com.gooduse.kanjicrossword.jp.pro.lifetime"
}

public enum LifetimePurchaseState: Equatable, Sendable {
    case checking
    case free
    case purchased
    case offlineCached
    case pending
    case unavailable
    case verificationFailed
    case failed(String)

    public var hasAccess: Bool {
        switch self {
        case .purchased, .offlineCached:
            true
        case .checking, .free, .pending, .unavailable, .verificationFailed, .failed:
            false
        }
    }
}

public struct LifetimeEntitlementSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let productID: String
    public let transactionID: UInt64
    public let originalTransactionID: UInt64
    public let purchaseDate: Date
    public let verifiedAt: Date

    public init(
        schemaVersion: Int = Self.currentSchemaVersion,
        productID: String,
        transactionID: UInt64,
        originalTransactionID: UInt64,
        purchaseDate: Date,
        verifiedAt: Date
    ) {
        self.schemaVersion = schemaVersion
        self.productID = productID
        self.transactionID = transactionID
        self.originalTransactionID = originalTransactionID
        self.purchaseDate = purchaseDate
        self.verifiedAt = verifiedAt
    }

    public func isValid(for expectedProductID: String) -> Bool {
        schemaVersion == Self.currentSchemaVersion
            && productID == expectedProductID
            && transactionID > 0
            && originalTransactionID > 0
    }
}
