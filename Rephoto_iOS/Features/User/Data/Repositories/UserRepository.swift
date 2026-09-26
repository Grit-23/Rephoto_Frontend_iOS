//
//  UserRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

final class UserRepository: UserRepositoryProtocol {
    private let adapter: NetworkAdapter
    private let networkClient: NetworkClient
    private let decoder: JSONDecoder

    init(
        adapter: NetworkAdapter,
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
        // 서버 로그아웃은 best-effort — 오프라인 등으로 실패해도 로컬 토큰은 반드시 지운다.
        // 여기서 throw하면 토큰이 Keychain에 남아 다음 실행 때 자동 로그인된다.
        _ = try? await adapter.request(UserAPITarget.logout)
        try await networkClient.logout()
    }

    func hasTokens() async -> Bool {
        await networkClient.isLoggedIn()
    }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {
        Task { await networkClient.setOnRefreshFailed(handler) }
    }
}
