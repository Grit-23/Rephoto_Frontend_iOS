//
//  StubUserUseCaseProvider.swift
//  UserFeatureTests
//
//  Created by Doyeon Kim on 11/15/26.
//

import Foundation
import UserDomainInterface
import UserDomainTesting
@testable import UserFeature

enum StubUserError: Error {
    case loginFailed
    case fetchFailed
    case logoutFailed
}

/// mockolo Mock 3개를 들고 있는 Provider. 테스트는 Mock의 Handler를 바꿔 UseCase 응답을 정한다.
final class StubUserUseCaseProvider: UserUseCaseProviderProtocol {
    let login = LoginUseCaseProtocolMock()
    let fetchUser = FetchUserUseCaseProtocolMock()
    let logout = LogoutUseCaseProtocolMock()
    var hasTokensResult = false
    private(set) var onRefreshFailed: (@Sendable () -> Void)?

    init() {
        // 반환값이 있는 Mock은 Handler가 없으면 fatalError라 기본을 실패로 둔다
        fetchUser.executeHandler = { throw StubUserError.fetchFailed }
    }

    func makeLoginUseCase() -> any LoginUseCaseProtocol { login }
    func makeFetchUserUseCase() -> any FetchUserUseCaseProtocol { fetchUser }
    func makeLogoutUseCase() -> any LogoutUseCaseProtocol { logout }

    func hasTokens() async -> Bool { hasTokensResult }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) async {
        onRefreshFailed = handler
    }
}

// Mock의 @Sendable Handler 안에서 호출되므로 테스트 모듈 기본 격리(MainActor)를 벗어난다
nonisolated extension UserInfo {
    static let stub = UserInfo(userId: 1, loginId: 100, name: "도연")
}
