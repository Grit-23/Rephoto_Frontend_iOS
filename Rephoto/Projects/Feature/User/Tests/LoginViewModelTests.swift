//
//  LoginViewModelTests.swift
//  UserFeatureTests
//
//  Created by Doyeon Kim on 11/15/26.
//

import Foundation
import Testing
import RephotoFoundation
import UserDomainInterface
import UserDomainTesting
@testable import UserFeature

/// 입력 검증과 로그인 성공 · 실패 시 `isLoading` · `error` 전이를 검증한다.
@Suite("LoginViewModel")
struct LoginViewModelTests {
    private let provider = StubUserUseCaseProvider()
    private let session: SessionStore
    private let sut: LoginViewModel

    init() {
        session = SessionStore(provider: provider)
        sut = LoginViewModel(session: session)
    }

    @Test("빈 필드 — 검증 에러를 담고 로그인을 호출하지 않는다")
    func emptyFieldsSetValidationError() async {
        sut.loginId = ""
        sut.password = "pw"

        await sut.login()

        #expect(sut.error == .domain(.emptyCredentials))
        #expect(provider.login.executeCallCount == 0)
        #expect(session.isLoggedIn == false)
    }

    @Test("로그인 성공 — 에러 없이 로그인 상태가 된다")
    func successLogsInWithoutError() async {
        provider.fetchUser.executeHandler = { .stub }
        sut.loginId = "dodle"
        sut.password = "pw"

        await sut.login()

        #expect(sut.error == nil)
        #expect(sut.isLoading == false)
        #expect(session.isLoggedIn)
    }

    @Test("로그인 실패 — 에러를 담고 로딩을 끝낸다")
    func failureSetsErrorAndEndsLoading() async {
        provider.login.executeHandler = { _, _ in throw NetworkError.timeout }
        sut.loginId = "dodle"
        sut.password = "pw"

        await sut.login()

        #expect(sut.error == .network(.timeout))
        #expect(sut.isShowingError)
        #expect(sut.isLoading == false)
        #expect(session.isLoggedIn == false)
    }

    @Test("isShowingError를 false로 쓰면 에러를 지운다")
    func dismissingAlertClearsError() {
        sut.error = .unknown(message: "에러")

        sut.isShowingError = false

        #expect(sut.error == nil)
    }
}
