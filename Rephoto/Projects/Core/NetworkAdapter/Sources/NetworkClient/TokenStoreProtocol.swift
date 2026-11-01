//
//  TokenStoreProtocol.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

public protocol TokenStore: Sendable {
    func getAccessToken() async -> String?
    func getRefreshToken() async -> String?
    func save(accessToken: String, refreshToken: String) async throws
    func clear() async throws
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
