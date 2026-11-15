//
//  StubUserUseCaseProvider.swift
//  UserFeatureTests
//
//  Created by Doyeon Kim on 11/15/26.
//

import Foundation
import Synchronization
import RephotoFoundation
import UserDomainInterface
import UserDomainTesting
@testable import UserFeature

/// mockolo Mock 3개를 들고 있는 Provider. 테스트는 Mock의 Handler를 바꿔 UseCase 응답을 정한다.
/// `Sendable` 프로토콜을 따르므로 바뀌는 값은 저장 프로퍼티 대신 `Mutex`에 둔다.
final class StubUserUseCaseProvider: UserUseCaseProviderProtocol {
    let login = LoginUseCaseProtocolMock()
    let fetchUser = FetchUserUseCaseProtocolMock()
    let logout = LogoutUseCaseProtocolMock()
    private let hasTokens = Mutex(false)
    private let refreshFailedHandler = Mutex<(@Sendable () -> Void)?>(nil)

    init() {
        // 반환값이 있는 Mock은 Handler가 없으면 fatalError라 기본을 실패로 둔다
        fetchUser.executeHandler = { throw NetworkError.noNetwork }
    }

    var hasTokensResult: Bool {
        get { hasTokens.withLock { $0 } }
        set { hasTokens.withLock { $0 = newValue } }
    }

    var onRefreshFailed: (@Sendable () -> Void)? {
        refreshFailedHandler.withLock { $0 }
    }

    func makeLoginUseCase() -> any LoginUseCaseProtocol { login }
    func makeFetchUserUseCase() -> any FetchUserUseCaseProtocol { fetchUser }
    func makeLogoutUseCase() -> any LogoutUseCaseProtocol { logout }

    func hasTokens() async -> Bool { hasTokensResult }

    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) async {
        refreshFailedHandler.withLock { $0 = handler }
    }
}

// Mock의 @Sendable Handler 안에서 호출되므로 테스트 모듈 기본 격리(MainActor)를 벗어난다
nonisolated extension UserInfo {
    static let stub = UserInfo(userId: 1, loginId: 100, name: "도연")
}
