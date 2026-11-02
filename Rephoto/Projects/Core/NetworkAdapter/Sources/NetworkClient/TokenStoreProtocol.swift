//
//  TokenStoreProtocol.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

/// NetworkClient actor 안에서 동기로 읽고 쓴다. 세션 확인과 저장 사이에 재진입하지 않는다.
public protocol TokenStore: Sendable {
    func load() -> TokenPair?
    func save(_ tokens: TokenPair) throws
    func clear() throws
}

public protocol TokenRefreshService: Sendable {
    func refresh(_ refreshToken: String) async throws -> TokenPair
}

public protocol AuthenticationPolicy: Sendable {
    /// 주어진 요청에 인증이 필요한지 판단
    func requireAuthentication(_ request: URLRequest) -> Bool

    /// 주어진 응답이 인증 실패(401)인지 판단
    func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool
}
