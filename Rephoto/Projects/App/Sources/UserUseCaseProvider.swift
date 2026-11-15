//
//  UserUseCaseProvider.swift
//  Rephoto
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import UserDomain
import UserDomainInterface
import UserFeature

final class UserUseCaseProvider: UserUseCaseProviderProtocol {
    private let userRepository: any UserRepositoryProtocol

    init(userRepository: any UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func makeLoginUseCase() -> any LoginUseCaseProtocol {
        LoginUseCase(repository: userRepository)
    }

    func makeFetchUserUseCase() -> any FetchUserUseCaseProtocol {
        FetchUserUseCase(repository: userRepository)
    }

    func makeLogoutUseCase() -> any LogoutUseCaseProtocol {
        LogoutUseCase(repository: userRepository)
    }

    func hasTokens() async -> Bool {
        await userRepository.hasTokens()
    }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) async {
        await userRepository.setOnRefreshFailed(handler)
    }
}
