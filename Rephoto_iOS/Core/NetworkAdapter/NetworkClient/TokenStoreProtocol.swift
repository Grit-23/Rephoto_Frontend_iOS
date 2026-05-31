//
//  TokenStoreProtocol.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

protocol TokenStore: Sendable {
    func getAccessToken() async -> String?
    func getRefreshToken() async -> String?
    func save(accessToken: String, refreshToken: String) async throws
    func clear() async throws
}

protocol TokenRefreshService: Sendable {
    func refresh(_ refreshToken: String) async throws -> TokenPair
}

protocol AuthenticationPolicy: Sendable {
    /// 주어진 요청에 인증이 필요한지 판단
    nonisolated func requireAuthentication(_ request: URLRequest) -> Bool

    /// 주어진 응답이 인증 실패(401)인지 판단
    nonisolated func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool
}
