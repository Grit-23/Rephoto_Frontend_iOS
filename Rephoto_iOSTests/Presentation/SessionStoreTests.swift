//
//  SessionStoreTests.swift
//  Rephoto_iOSTests
//
//  앱 전역 세션 상태(SessionStore)의 동작 검증.
//  - restore: 토큰 유무에 따른 자동 로그인
//  - login/logout: 성공/실패 시 상태 전이
//  - 토큰 리프레시 실패 콜백 → 강제 로그아웃
//

import XCTest
@testable import Rephoto_iOS

@MainActor
final class SessionStoreTests: XCTestCase {

    private var provider: MockUserUseCaseProvider!
    private var sut: SessionStore!

    override func setUp() async throws {
        try await super.setUp()
        provider = MockUserUseCaseProvider()
        sut = SessionStore(provider: provider)
    }

    override func tearDown() async throws {
        sut = nil
        provider = nil
        try await super.tearDown()
    }

    private let stubUser = UserInfo(userId: 1, loginId: 100, name: "도연")

    // MARK: - restore

    func test_restore_withoutTokens_staysLoggedOut() async {
        provider.hasTokensResult = false

        await sut.restore()

        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.userInfo)
        XCTAssertEqual(provider.fetchUserCallCount, 0)
    }

    func test_restore_withTokens_logsInAndFetchesUser() async {
        provider.hasTokensResult = true
        provider.fetchUserResult = .success(stubUser)

        await sut.restore()

        XCTAssertTrue(sut.isLoggedIn)
        XCTAssertEqual(sut.userInfo?.userId, 1)
        XCTAssertEqual(sut.name, "도연")
    }

    func test_restore_withTokens_fetchUserFails_keepsLoggedInWithoutUserInfo() async {
        provider.hasTokensResult = true
        provider.fetchUserResult = .failure(MockUserError.fetchFailed)

        await sut.restore()

        XCTAssertTrue(sut.isLoggedIn)
        XCTAssertNil(sut.userInfo)
        XCTAssertEqual(sut.name, "리포토")
    }

    // MARK: - login

    func test_login_success_setsLoggedInAndUserInfo() async throws {
        provider.fetchUserResult = .success(stubUser)

        try await sut.login(id: "dodle", password: "pw")

        XCTAssertTrue(sut.isLoggedIn)
        XCTAssertEqual(sut.userInfo?.name, "도연")
        XCTAssertEqual(provider.lastLoginId, "dodle")
        XCTAssertEqual(provider.lastPassword, "pw")
    }

    func test_login_failure_throwsAndStaysLoggedOut() async {
        provider.loginResult = .failure(MockUserError.loginFailed)

        do {
            try await sut.login(id: "dodle", password: "pw")
            XCTFail("로그인 실패 시 에러가 throw되어야 한다")
        } catch {}

        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertEqual(provider.fetchUserCallCount, 0)
    }

    // MARK: - logout

    func test_logout_clearsSessionState() async throws {
        provider.fetchUserResult = .success(stubUser)
        try await sut.login(id: "dodle", password: "pw")

        await sut.logout()

        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.userInfo)
        XCTAssertEqual(provider.logoutCallCount, 1)
    }

    func test_logout_serverFailure_stillClearsLocalState() async throws {
        provider.fetchUserResult = .success(stubUser)
        provider.logoutResult = .failure(MockUserError.logoutFailed)
        try await sut.login(id: "dodle", password: "pw")

        await sut.logout()

        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.userInfo)
    }

    // MARK: - 토큰 리프레시 실패 콜백

    func test_refreshFailedCallback_forcesLogout() async throws {
        provider.fetchUserResult = .success(stubUser)
        try await sut.login(id: "dodle", password: "pw")
        XCTAssertTrue(sut.isLoggedIn)

        provider.onRefreshFailed?()
        // 콜백이 Task { @MainActor }로 감싸 실행되므로 메인 액터에 제어를 양보한다
        for _ in 0..<10 where sut.isLoggedIn {
            await Task.yield()
        }

        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.userInfo)
    }
}
