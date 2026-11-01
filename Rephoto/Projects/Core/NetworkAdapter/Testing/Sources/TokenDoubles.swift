//
//  TokenDoubles.swift
//  NetworkAdapterTesting
//
//  Created by Doyeon Kim on 6/6/26.
//

import Foundation
import NetworkAdapter

// MARK: - MockTokenStore

/// 메모리에만 저장하는 토큰 저장소. Keychain 없이 `NetworkClient`를 조립할 때 쓴다.
public final actor MockTokenStore: TokenStore {
    private var access: String?
    private var refresh: String?

    public init(accessToken: String? = "test-access", refreshToken: String? = "test-refresh") {
        self.access = accessToken
        self.refresh = refreshToken
    }

    public func getAccessToken() async -> String? { access }
    public func getRefreshToken() async -> String? { refresh }

    public func save(accessToken: String, refreshToken: String) async throws {
        access = accessToken
        refresh = refreshToken
    }

    public func clear() async throws {
        access = nil
        refresh = nil
    }
}

// MARK: - MockTokenRefreshService

/// 항상 실패하는 토큰 갱신 서비스. 갱신 경로를 타지 않는 테스트의 기본값이다.
public struct MockTokenRefreshService: TokenRefreshService {
    public init() {}

    public func refresh(_ refreshToken: String) async throws -> TokenPair {
        throw URLError(.userAuthenticationRequired)
    }
}
