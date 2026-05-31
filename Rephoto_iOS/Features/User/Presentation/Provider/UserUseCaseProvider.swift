//
//  UserUseCaseProvider.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

protocol UserUseCaseProviderProtocol {
    func login() -> LoginUseCaseProtocol
    func fetchUser() -> FetchUserUseCaseProtocol
    func logout() -> LogoutUseCaseProtocol
    func hasTokens() async -> Bool
    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void)
}

final class UserUseCaseProvider: UserUseCaseProviderProtocol {
    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func login() -> LoginUseCaseProtocol {
        LoginUseCase(repository: userRepository)
    }

    func fetchUser() -> FetchUserUseCaseProtocol {
        FetchUserUseCase(repository: userRepository)
    }

    func logout() -> LogoutUseCaseProtocol {
        LogoutUseCase(repository: userRepository)
    }

    func hasTokens() async -> Bool {
        await userRepository.hasTokens()
    }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {
        userRepository.setOnRefreshFailed(handler)
    }
}
