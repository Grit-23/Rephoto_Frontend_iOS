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
    // 개발 빌드에서 세션 복원(자동 로그인) 경로를 타서 로그인 화면을 건너뛰도록 true 반환
    func hasTokens() async -> Bool { true }
    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {}
}

// MARK: - Mock UseCases

enum MockLoginError: LocalizedError {
    case invalidCredentials
    var errorDescription: String? { "아이디 또는 비밀번호가 올바르지 않습니다." }
}

private struct MockLoginUseCase: LoginUseCaseProtocol {
    func execute(loginId: String, password: String) async throws {
        try await Task.sleep(for: .seconds(1))   // 네트워크 지연 흉내
        guard loginId == "test", password == "1234" else {
            throw MockLoginError.invalidCredentials
        }
    }
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
