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
    var hasTokens: Bool { get }
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

    var hasTokens: Bool {
        userRepository.hasTokens
    }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {
        userRepository.setOnRefreshFailed(handler)
    }
}
