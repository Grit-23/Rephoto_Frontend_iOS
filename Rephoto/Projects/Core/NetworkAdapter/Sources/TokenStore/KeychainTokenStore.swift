//
//  KeychainTokenStore.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation
import Security

public actor KeychainTokenStore: TokenStore {

    private let service: String
    private let items: KeychainItemStore
    private let accessTokenKey: String = "accessToken"
    private let refreshTokenKey: String = "refreshToken"

    public init(service: String = "com.rephoto.tokens") {
        self.init(service: service, items: SecItemStore())
    }

    /// Keychain 대신 다른 항목 저장소를 쓴다. 호스트 앱 없이 도는 테스트가 메모리 더블을 넣는다.
    init(service: String, items: KeychainItemStore) {
        self.service = service
        self.items = items
    }

    // MARK: - TokenStore Protocol

    public func getAccessToken() async -> String? {
        return load(key: accessTokenKey)
    }

    public func getRefreshToken() async -> String? {
        return load(key: refreshTokenKey)
    }

    /// access·refresh를 순서대로 저장한다. 두 번째 쓰기가 실패하면 첫 번째를 이전 값으로 되돌려
    /// 쌍이 어긋나지 않게 한다. 이전 값이 없었다면 삭제한다.
    public func save(accessToken: String, refreshToken: String) async throws {
        let previousAccessToken = load(key: accessTokenKey)
        try save(key: accessTokenKey, value: accessToken)
        do {
            try save(key: refreshTokenKey, value: refreshToken)
        } catch {
            if let previousAccessToken {
                try? save(key: accessTokenKey, value: previousAccessToken)
            } else {
                items.delete(service: service, account: accessTokenKey)
            }
            throw error
        }
    }

    public func clear() async throws {
        items.delete(service: service, account: accessTokenKey)
        items.delete(service: service, account: refreshTokenKey)
    }

    // MARK: - Private Methods

    private func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try items.write(data, service: service, account: key)
    }

    private func load(key: String) -> String? {
        guard let data = items.read(service: service, account: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Item Store

/// Keychain 항목 하나를 읽고 쓰는 최소 인터페이스. `KeychainTokenStore`는 이것으로만 Keychain에 닿는다.
protocol KeychainItemStore: Sendable {
    func read(service: String, account: String) -> Data?
    func write(_ data: Data, service: String, account: String) throws
    func delete(service: String, account: String)
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

    func delete(service: String, account: String) {
        SecItemDelete(baseQuery(service: service, account: account) as CFDictionary)
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
    case encodingFailed
    case saveFailed(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "토큰 인코딩 실패"
        case .saveFailed(let status):
            return "Keychain 저장 실패 (status: \(status))"
        }
    }
}
