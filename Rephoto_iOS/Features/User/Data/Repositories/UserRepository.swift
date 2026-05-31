//
//  UserRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import Moya

final class UserRepository: UserRepositoryProtocol {
    private let adapter: MoyaNetworkAdapter
    private let networkClient: NetworkClient
    private let decoder: JSONDecoder

    init(
        adapter: MoyaNetworkAdapter,
        networkClient: NetworkClient,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.networkClient = networkClient
        self.decoder = decoder
    }

    func login(loginId: String, password: String) async throws {
        let response = try await adapter.request(UserAPITarget.login(loginId: loginId, password: password))
        let dto = try decoder.decode(LoginResponseDTO.self, from: response.data)
        try await networkClient.saveTokens(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken
        )
    }

    func fetchUser() async throws -> UserInfo {
        let response = try await adapter.request(UserAPITarget.getUser)
        let dto = try decoder.decode(UserInfoResponseDTO.self, from: response.data)
        return dto.toDomain()
    }

    func logout() async throws {
        _ = try await adapter.request(UserAPITarget.logout)
        try await networkClient.logout()
    }

    func hasTokens() async -> Bool {
        await networkClient.isLoggedIn()
    }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {
        _Concurrency.Task { await networkClient.setOnRefreshFailed(handler) }
    }
}
