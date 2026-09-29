import Foundation

public protocol LifetimeEntitlementCaching: Sendable {
    func load() throws -> LifetimeEntitlementSnapshot?
    func save(_ snapshot: LifetimeEntitlementSnapshot) throws
    func clear() throws
}

public enum LifetimeEntitlementCacheError: Error, LocalizedError, Sendable {
    case encodingFailed
    case decodingFailed
    case keychain(Int32)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            "購入情報を安全に保存できませんでした。"
        case .decodingFailed:
            "保存されている購入情報を読み取れませんでした。"
        case .keychain(let status):
            "購入情報の保存領域でエラーが発生しました（\(status)）。"
        }
    }
}

#if canImport(Security)
import Security

public final class KeychainLifetimeEntitlementCache: LifetimeEntitlementCaching, @unchecked Sendable {
    private let service: String
    private let account: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        service: String? = nil,
        account: String = "kanji-crossword-lifetime-entitlement-v1"
    ) {
        self.service = service
            ?? Bundle.main.bundleIdentifier
            ?? "com.gooduse.kanjicrossword"
        self.account = account
    }

    public func load() throws -> LifetimeEntitlementSnapshot? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw LifetimeEntitlementCacheError.keychain(Int32(status))
        }
        guard let data = result as? Data else {
            throw LifetimeEntitlementCacheError.decodingFailed
        }
        do {
            return try decoder.decode(LifetimeEntitlementSnapshot.self, from: data)
        } catch {
            throw LifetimeEntitlementCacheError.decodingFailed
        }
    }

    public func save(_ snapshot: LifetimeEntitlementSnapshot) throws {
        let data: Data
        do {
            data = try encoder.encode(snapshot)
        } catch {
            throw LifetimeEntitlementCacheError.encodingFailed
        }

        let status = SecItemCopyMatching(baseQuery as CFDictionary, nil)
        if status == errSecItemNotFound {
            var attributes = baseQuery
            attributes[kSecValueData as String] = data
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw LifetimeEntitlementCacheError.keychain(Int32(addStatus))
            }
            return
        }

        guard status == errSecSuccess else {
            throw LifetimeEntitlementCacheError.keychain(status)
        }

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        guard updateStatus == errSecSuccess else {
            throw LifetimeEntitlementCacheError.keychain(Int32(updateStatus))
        }
    }

    public func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw LifetimeEntitlementCacheError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
    }
}
#else
public final class KeychainLifetimeEntitlementCache: LifetimeEntitlementCaching, @unchecked Sendable {
    public init(service: String? = nil, account: String = "kanji-crossword-lifetime-entitlement-v1") {}

    public func load() throws -> LifetimeEntitlementSnapshot? { nil }
    public func save(_ snapshot: LifetimeEntitlementSnapshot) throws {}
    public func clear() throws {}
}
#endif
