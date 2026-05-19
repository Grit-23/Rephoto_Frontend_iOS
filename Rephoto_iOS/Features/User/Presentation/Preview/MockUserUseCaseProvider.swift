//
//  MockUserUseCaseProvider.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

#if DEBUG
import Foundation

final class MockUserUseCaseProvider: UserUseCaseProviderProtocol {
    func login() -> LoginUseCaseProtocol { MockLoginUseCase() }
    func fetchUser() -> FetchUserUseCaseProtocol { MockFetchUserUseCase() }
    func logout() -> LogoutUseCaseProtocol { MockLogoutUseCase() }
    var hasTokens: Bool { false }
    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {}
}

// MARK: - Mock UseCases

private struct MockLoginUseCase: LoginUseCaseProtocol {
    func execute(loginId: String, password: String) async throws {}
}

private struct MockFetchUserUseCase: FetchUserUseCaseProtocol {
    func execute() async throws -> UserInfo {
        UserInfo(userId: 1, loginId: 1, name: "테스트유저")
    }
}

private struct MockLogoutUseCase: LogoutUseCaseProtocol {
    func execute() async throws {}
}
#endif
