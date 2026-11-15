//
//  UserRepository.swift
//  UserDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import NetworkAdapter
import UserDomainInterface

public final class UserRepository: UserRepositoryProtocol, Sendable {
    private let adapter: NetworkAdapter
    private let networkClient: NetworkClient
    private let decoder: JSONDecoder

    public init(
        adapter: NetworkAdapter,
        networkClient: NetworkClient,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.networkClient = networkClient
        self.decoder = decoder
    }

    @concurrent
    public func login(loginId: String, password: String) async throws {
        let data = try await adapter.request(UserAPITarget.login(loginId: loginId, password: password))
        let dto = try decoder.decode(LoginResponseDTO.self, from: data)
        try await networkClient.saveTokens(accessToken: dto.accessToken, refreshToken: dto.refreshToken)
    }

    @concurrent
    public func fetchUser() async throws -> UserInfo {
        let data = try await adapter.request(UserAPITarget.getUser)
        let dto = try decoder.decode(UserInfoResponseDTO.self, from: data)
        return dto.toDomain()
    }

    public func logout() async throws {
        // 서버 로그아웃이 실패해도 로컬 토큰은 지운다. 남으면 다음 실행 때 자동 로그인된다.
        _ = try? await adapter.request(UserAPITarget.logout)
        try await networkClient.logout()
    }

    public func hasTokens() async -> Bool {
        await networkClient.isLoggedIn()
    }

    public func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {
        Task { await networkClient.setOnRefreshFailed(handler) }
    }
}
