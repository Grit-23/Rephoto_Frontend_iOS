//
//  SessionStoreTests.swift
//  UserFeatureTests
//
//  Created by Doyeon Kim on 11/15/26.
//

import Foundation
import Testing
import UserDomainInterface
import UserDomainTesting
@testable import UserFeature

/// 세션 복원 · 로그인 · 로그아웃의 상태 전이와 토큰 갱신 실패 시 강제 로그아웃을 검증한다.
@Suite("SessionStore")
struct SessionStoreTests {
    private let provider = StubUserUseCaseProvider()

    private func makeSUT() -> SessionStore {
        SessionStore(provider: provider)
    }

    // MARK: - restore

    @Test("restore — 토큰이 없으면 로그아웃 상태로 남고 사용자 정보를 조회하지 않는다")
    func restoreWithoutTokensStaysLoggedOut() async {
        provider.hasTokensResult = false
        let sut = makeSUT()

        await sut.restore()

        #expect(sut.isLoggedIn == false)
        #expect(sut.userInfo == nil)
        #expect(provider.fetchUser.executeCallCount == 0)
    }

    @Test("restore — 토큰이 있으면 로그인 상태가 되고 사용자 정보를 채운다")
    func restoreWithTokensLogsInAndFetchesUser() async {
        provider.hasTokensResult = true
        provider.fetchUser.executeHandler = { .stub }
        let sut = makeSUT()

        await sut.restore()

        #expect(sut.isLoggedIn)
        #expect(sut.userInfo == .stub)
        #expect(sut.name == "도연")
    }

    @Test("restore — 사용자 정보 조회가 실패해도 로그인 상태는 유지하고 기본 이름을 쓴다")
    func restoreKeepsLoggedInWhenFetchUserFails() async {
        provider.hasTokensResult = true
        let sut = makeSUT()

        await sut.restore()

        #expect(sut.isLoggedIn)
        #expect(sut.userInfo == nil)
        #expect(sut.name == "리포토")
    }

    // MARK: - login

    @Test("login 성공 — 자격증명을 그대로 넘기고 로그인 상태와 사용자 정보를 채운다")
    func loginSuccessSetsLoggedInAndUserInfo() async throws {
        provider.fetchUser.executeHandler = { .stub }
        let sut = makeSUT()

        try await sut.login(id: "dodle", password: "pw")

        let arguments = try #require(provider.login.executeArgValues.first)
        #expect(arguments.loginId == "dodle")
        #expect(arguments.password == "pw")
        #expect(sut.isLoggedIn)
        #expect(sut.userInfo == .stub)
    }

    @Test("login 실패 — 에러를 던지고 로그아웃 상태로 남는다")
    func loginFailureThrowsAndStaysLoggedOut() async {
        provider.login.executeHandler = { _, _ in throw StubUserError.loginFailed }
        let sut = makeSUT()

        await #expect(throws: StubUserError.loginFailed) {
            try await sut.login(id: "dodle", password: "pw")
        }

        #expect(sut.isLoggedIn == false)
        #expect(provider.fetchUser.executeCallCount == 0)
    }

    // MARK: - logout

    @Test("logout — 세션 상태를 비우고 로그아웃 UseCase를 한 번 호출한다")
    func logoutClearsSessionState() async throws {
        provider.fetchUser.executeHandler = { .stub }
        let sut = makeSUT()
        try await sut.login(id: "dodle", password: "pw")

        await sut.logout()

        #expect(sut.isLoggedIn == false)
        #expect(sut.userInfo == nil)
        #expect(provider.logout.executeCallCount == 1)
    }

    @Test("logout — 로그아웃 UseCase가 실패해도 화면 상태는 비운다")
    func logoutClearsStateEvenWhenUseCaseFails() async throws {
        provider.fetchUser.executeHandler = { .stub }
        provider.logout.executeHandler = { throw StubUserError.logoutFailed }
        let sut = makeSUT()
        try await sut.login(id: "dodle", password: "pw")

        await sut.logout()

        #expect(sut.isLoggedIn == false)
        #expect(sut.userInfo == nil)
    }

    // MARK: - 토큰 갱신 실패

    @Test("restore가 등록한 핸들러가 호출되면 강제 로그아웃된다")
    func refreshFailureForcesLogout() async throws {
        provider.fetchUser.executeHandler = { .stub }
        let sut = makeSUT()
        await sut.restore()
        try await sut.login(id: "dodle", password: "pw")
        let onRefreshFailed = try #require(provider.onRefreshFailed)

        onRefreshFailed()
        // 핸들러가 Task { @MainActor }로 넘기므로 메인 액터에 제어를 양보한다
        for _ in 0..<10 where sut.isLoggedIn {
            await Task.yield()
        }

        #expect(sut.isLoggedIn == false)
        #expect(sut.userInfo == nil)
    }
}
