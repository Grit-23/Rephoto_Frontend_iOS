//
//  TokenDoubles.swift
//  NetworkAdapterTesting
//
//  Created by Doyeon Kim on 6/6/26.
//

import Foundation
import Synchronization
import NetworkAdapter

// MARK: - MockTokenStore

/// 메모리에만 저장하는 토큰 저장소. Keychain 없이 `NetworkClient`를 조립할 때 쓴다.
public final class MockTokenStore: TokenStore {
    private let tokens: Mutex<TokenPair?>

    public init(accessToken: String? = "test-access", refreshToken: String? = "test-refresh") {
        let pair: TokenPair? = if let accessToken, let refreshToken {
            TokenPair(accessToken: accessToken, refreshToken: refreshToken)
        } else {
            nil
        }
        tokens = Mutex(pair)
    }

    public func load() -> TokenPair? { tokens.withLock { $0 } }

    public func save(_ tokens: TokenPair) {
        self.tokens.withLock { $0 = tokens }
    }

    public func clear() {
        tokens.withLock { $0 = nil }
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
