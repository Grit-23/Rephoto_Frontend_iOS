//
//  LoginViewModelTests.swift
//  Rephoto_iOSTests
//
//  로그인 화면 ViewModel의 표현 상태 검증.
//  - 입력 검증(빈 필드) 시 에러 메시지, 세션 호출 없음
//  - 로그인 성공/실패 시 isLoading/errorMessage 상태 전이
//

import XCTest
@testable import Rephoto_iOS

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var provider: MockUserUseCaseProvider!
    private var session: SessionStore!
    private var sut: LoginViewModel!

    override func setUp() async throws {
        try await super.setUp()
        provider = MockUserUseCaseProvider()
        session = SessionStore(provider: provider)
        sut = LoginViewModel(session: session)
    }

    override func tearDown() async throws {
        sut = nil
        session = nil
        provider = nil
        try await super.tearDown()
    }

    func test_login_emptyFields_setsValidationError_withoutCallingSession() async {
        sut.loginId = ""
        sut.password = "pw"

        await sut.login()

        XCTAssertEqual(sut.errorMessage, "아이디와 비밀번호를 입력해주세요.")
        XCTAssertEqual(provider.loginCallCount, 0)
        XCTAssertFalse(session.isLoggedIn)
    }

    func test_login_success_logsInWithoutError() async {
        provider.fetchUserResult = .success(UserInfo(userId: 1, loginId: 100, name: "도연"))
        sut.loginId = "dodle"
        sut.password = "pw"

        await sut.login()

        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(session.isLoggedIn)
    }

    func test_login_failure_setsErrorMessage_andEndsLoading() async {
        provider.loginResult = .failure(MockUserError.loginFailed)
        sut.loginId = "dodle"
        sut.password = "pw"

        await sut.login()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.isShowingError)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(session.isLoggedIn)
    }

    func test_isShowingError_setFalse_clearsErrorMessage() {
        sut.errorMessage = "에러"

        sut.isShowingError = false

        XCTAssertNil(sut.errorMessage)
    }
}
