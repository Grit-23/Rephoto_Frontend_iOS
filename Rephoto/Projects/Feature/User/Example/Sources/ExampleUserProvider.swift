//
//  ExampleUserProvider.swift
//  UserFeatureExample
//
//  Created by Doyeon Kim on 11/15/26.
//

import Foundation
import PreviewSupport
import UserDomain
import UserDomainInterface
import UserFeature

/// PreviewSupport Repository + 실제 UseCase. App의 `UserUseCaseProvider`와 같은 모양으로 조립한다.
final class ExampleUserProvider: UserUseCaseProviderProtocol {
    let repository: PreviewUserRepository

    init(isLoggedIn: Bool) {
        self.repository = PreviewUserRepository(isLoggedIn: isLoggedIn)
    }

    func makeLoginUseCase() -> any LoginUseCaseProtocol {
        LoginUseCase(repository: repository)
    }

    func makeFetchUserUseCase() -> any FetchUserUseCaseProtocol {
        FetchUserUseCase(repository: repository)
    }

    func makeLogoutUseCase() -> any LogoutUseCaseProtocol {
        LogoutUseCase(repository: repository)
    }

    func hasTokens() async -> Bool {
        await repository.hasTokens()
    }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) async {
        await repository.setOnRefreshFailed(handler)
    }
}
