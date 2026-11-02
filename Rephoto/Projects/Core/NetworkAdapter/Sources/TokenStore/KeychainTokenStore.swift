//
//  KeychainTokenStore.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation
import Security

public struct KeychainTokenStore: TokenStore {

    private let service: String
    private let items: KeychainItemStore
    private let tokensKey = "tokens"

    public init(service: String = "com.rephoto.tokens") {
        self.init(service: service, items: SecItemStore())
    }

    /// Keychain 대신 다른 항목 저장소를 쓴다. 호스트 앱 없이 도는 테스트가 메모리 더블을 넣는다.
    init(service: String, items: KeychainItemStore) {
        self.service = service
        self.items = items
    }

    // MARK: - TokenStore Protocol

    public func load() -> TokenPair? {
        guard let data = items.read(service: service, account: tokensKey) else { return nil }
        return try? JSONDecoder().decode(TokenPair.self, from: data)
    }

    /// 두 토큰을 하나의 Keychain 항목으로 저장해 서로 다른 세션의 토큰이 섞이지 않게 한다.
    public func save(_ tokens: TokenPair) throws {
        let data = try JSONEncoder().encode(tokens)
        try items.write(data, service: service, account: tokensKey)
    }

    public func clear() throws {
        try items.delete(service: service, account: tokensKey)
    }
}

// MARK: - Item Store

/// Keychain 항목 하나를 읽고 쓰는 최소 인터페이스. `KeychainTokenStore`는 이것으로만 Keychain에 닿는다.
protocol KeychainItemStore: Sendable {
    func read(service: String, account: String) -> Data?
    func write(_ data: Data, service: String, account: String) throws
    func delete(service: String, account: String) throws
}

/// `SecItem*` API로 generic password 항목을 다루는 실제 구현.
struct SecItemStore: KeychainItemStore {

    func read(service: String, account: String) -> Data? {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// 기존 항목이 있으면 값만 갱신하고, 없을 때만 새로 추가한다.
    ///
    /// delete 후 add 방식은 add가 실패하면(재부팅 후 첫 잠금 해제 전 등) 옛 값이 이미 지워져
    /// 토큰이 유실된다. update가 실패해도 기존 항목은 그대로 남는다.
    func write(_ data: Data, service: String, account: String) throws {
        let query = baseQuery(service: service, account: account)
        let attributesToUpdate: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.saveFailed(status: addStatus)
            }
        default:
            throw KeychainError.saveFailed(status: updateStatus)
        }
    }

    func delete(service: String, account: String) throws {
        let status = SecItemDelete(baseQuery(service: service, account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    private func baseQuery(service: String, account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

// MARK: - Errors

public enum KeychainError: Error, LocalizedError {
    case saveFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain 저장 실패 (status: \(status))"
        case .deleteFailed(let status):
            return "Keychain 삭제 실패 (status: \(status))"
        }
    }
}
