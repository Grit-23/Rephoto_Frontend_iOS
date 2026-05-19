//
//  UserRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import Moya

final class UserRepository: UserRepositoryProtocol {
    private let plainProvider: MoyaProvider<UserAPITarget>
    private let authedProvider: AuthedProvider
    private let tokenStore: TokenStore
    private let decoder: JSONDecoder

    init(
        plainProvider: MoyaProvider<UserAPITarget>,
        authedProvider: AuthedProvider,
        tokenStore: TokenStore = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.plainProvider = plainProvider
        self.authedProvider = authedProvider
        self.tokenStore = tokenStore
        self.decoder = decoder
    }

    func login(loginId: String, password: String) async throws {
        let response = try await plainProvider.request(.login(loginId: loginId, password: password))
        let dto = try decoder.decode(LoginResponseDTO.self, from: response.data)
        tokenStore.save(TokenPair(accessToken: dto.accessToken, refreshToken: dto.refreshToken))
    }

    func fetchUser() async throws -> UserInfo {
        let response = try await authedProvider.request(.getUser)
        let dto = try decoder.decode(UserInfoResponseDTO.self, from: response.data)
        return dto.toDomain()
    }

    func logout() async throws {
        _ = try await authedProvider.request(.logout)
        tokenStore.clear()
    }

    var hasTokens: Bool {
        tokenStore.hasTokens
    }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {
        authedProvider.onRefreshFailed = handler
    }
}
