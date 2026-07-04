//
//  MockUserUseCaseProvider.swift
//  Rephoto_iOSTests
//
//  SessionStore / LoginViewModel 테스트용 mock.
//  - 각 UseCase의 결과를 Result로 미리 설정
//  - 호출 횟수/인자를 기록해 상호작용 검증 가능
//

import Foundation
@testable import Rephoto_iOS

enum MockUserError: Error {
    case loginFailed
    case fetchFailed
    case logoutFailed
}

final class MockUserUseCaseProvider: UserUseCaseProviderProtocol {

    // 테스트에서 시나리오별로 설정하는 결과값
    var hasTokensResult = false
    var loginResult: Result<Void, Error> = .success(())
    var fetchUserResult: Result<UserInfo, Error> = .failure(MockUserError.fetchFailed)
    var logoutResult: Result<Void, Error> = .success(())

    // 호출 기록
    private(set) var loginCallCount = 0
    private(set) var lastLoginId: String?
    private(set) var lastPassword: String?
    private(set) var fetchUserCallCount = 0
    private(set) var logoutCallCount = 0
    private(set) var onRefreshFailed: (@Sendable () -> Void)?

    func hasTokens() async -> Bool {
        hasTokensResult
    }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {
        onRefreshFailed = handler
    }

    func login() -> LoginUseCaseProtocol {
        StubLoginUseCase { id, password in
            self.loginCallCount += 1
            self.lastLoginId = id
            self.lastPassword = password
            try self.loginResult.get()
        }
    }

    func fetchUser() -> FetchUserUseCaseProtocol {
        StubFetchUserUseCase {
            self.fetchUserCallCount += 1
            return try self.fetchUserResult.get()
        }
    }

    func logout() -> LogoutUseCaseProtocol {
        StubLogoutUseCase {
            self.logoutCallCount += 1
            try self.logoutResult.get()
        }
    }
}

private struct StubLoginUseCase: LoginUseCaseProtocol {
    let onExecute: (String, String) throws -> Void
    func execute(loginId: String, password: String) async throws {
        try onExecute(loginId, password)
    }
}

private struct StubFetchUserUseCase: FetchUserUseCaseProtocol {
    let onExecute: () throws -> UserInfo
    func execute() async throws -> UserInfo {
        try onExecute()
    }
}

private struct StubLogoutUseCase: LogoutUseCaseProtocol {
    let onExecute: () throws -> Void
    func execute() async throws {
        try onExecute()
    }
}
