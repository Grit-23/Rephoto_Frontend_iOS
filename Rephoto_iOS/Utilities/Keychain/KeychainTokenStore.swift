//
//  KeychainTokenStore.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation
import Security

public actor KeychainTokenStore: TokenStore {

    private let service: String
    private let accessTokenKey: String = "accessToken"
    private let refreshTokenKey: String = "refreshToken"

    public init(service: String = "com.rephoto.tokens") {
        self.service = service
    }

    // MARK: - TokenStore Protocol

    public func getAccessToken() async -> String? {
        return loadFromKeychain(key: accessTokenKey)
    }

    public func getRefreshToken() async -> String? {
        return loadFromKeychain(key: refreshTokenKey)
    }

    /// access·refresh를 순서대로 저장한다. 두 번째 쓰기가 실패하면 첫 번째를 이전 값으로 되돌려
    /// 쌍이 어긋나지 않게 한다. 이전 값이 없었다면 삭제한다.
    public func save(accessToken: String, refreshToken: String) async throws {
        let previousAccessToken = loadFromKeychain(key: accessTokenKey)
        try saveToKeychain(key: accessTokenKey, value: accessToken)
        do {
            try saveToKeychain(key: refreshTokenKey, value: refreshToken)
        } catch {
            if let previousAccessToken {
                try? saveToKeychain(key: accessTokenKey, value: previousAccessToken)
            } else {
                deleteFromKeychain(key: accessTokenKey)
            }
            throw error
        }
    }

    public func clear() async throws {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
    }

    // MARK: - Private Methods

    /// 기존 항목이 있으면 값만 갱신하고, 없을 때만 새로 추가한다.
    ///
    /// delete 후 add 방식은 add가 실패하면(재부팅 후 첫 잠금 해제 전 등) 옛 값이 이미 지워져
    /// 토큰이 유실된다. update가 실패해도 기존 항목은 그대로 남는다.
    private func saveToKeychain(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data
        ]

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

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
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
