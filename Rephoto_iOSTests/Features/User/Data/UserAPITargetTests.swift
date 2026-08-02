//
//  UserAPITargetTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 8/2/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// UserAPITarget의 엔드포인트 계약 검증.
///
/// 조회·수정·삭제가 `/users` 하나를 method로만 구분하므로, path만으로는 오설정을 잡을 수 없다.
/// 또 `/login` `/join` `/auth/refresh`는 DefaultAuthenticationPolicy가 공개 경로로 판정하는 값이라,
/// 여기서 path가 바뀌면 토큰 주입 여부까지 함께 틀어진다.
@Suite("UserAPITarget — 엔드포인트 계약")
struct UserAPITargetTests {

    // MARK: - path / method

    @Test("join — POST /join")
    func join() {
        let target = UserAPITarget.join(loginId: "dodle", password: "secret!", username: "도연")

        #expect(target.path == "/join")
        #expect(target.method == .post)
    }

    @Test("login — POST /login")
    func login() {
        let target = UserAPITarget.login(loginId: "dodle", password: "secret!")

        #expect(target.path == "/login")
        #expect(target.method == .post)
    }

    @Test("logout — POST /logout, 바디 없음")
    func logout() {
        let target = UserAPITarget.logout

        #expect(target.path == "/logout")
        #expect(target.method == .post)
        #expect(target.task.isPlain)
    }

    @Test("refreshToken — POST /auth/refresh")
    func refreshTokenPathAndMethod() {
        let target = UserAPITarget.refreshToken(refreshToken: "refresh-token-value")

        #expect(target.path == "/auth/refresh")
        #expect(target.method == .post)
    }

    /// `/users`는 세 케이스가 공유하므로 method가 유일한 구분자다.
    @Test("getUser — GET /users")
    func getUser() {
        let target = UserAPITarget.getUser

        #expect(target.path == "/users")
        #expect(target.method == .get)
        #expect(target.task.isPlain)
    }

    @Test("updateUser — PUT /users")
    func updateUser() {
        let target = UserAPITarget.updateUser(username: "도연", password: "new-secret!")

        #expect(target.path == "/users")
        #expect(target.method == .put)
    }

    @Test("deleteUser — DELETE /users")
    func deleteUser() {
        let target = UserAPITarget.deleteUser

        #expect(target.path == "/users")
        #expect(target.method == .delete)
        #expect(target.task.isPlain)
    }

    @Test("/users를 공유하는 세 케이스는 method로만 구분된다")
    func usersPathIsDisambiguatedByMethodOnly() {
        let methods = [UserAPITarget.getUser, .updateUser(username: "도연", password: "pw"), .deleteUser]
            .map(\.method)

        #expect(Set(methods) == [.get, .put, .delete])
    }

    // MARK: - task

    @Test("join — 가입 정보 3개를 JSON 바디로 싣는다")
    func joinCarriesCredentials() throws {
        let target = UserAPITarget.join(loginId: "dodle", password: "secret!", username: "도연")

        let body = try #require(target.task.jsonBody(as: JoinRequestDTO.self), "task가 .jsonEncodable이 아님")
        #expect(body.loginId == "dodle")
        #expect(body.password == "secret!")
        #expect(body.username == "도연")
    }

    @Test("login — 자격증명을 JSON 바디로 싣는다")
    func loginCarriesCredentials() throws {
        let target = UserAPITarget.login(loginId: "dodle", password: "secret!")

        let body = try #require(target.task.jsonBody(as: LoginRequestDTO.self), "task가 .jsonEncodable이 아님")
        #expect(body.loginId == "dodle")
        #expect(body.password == "secret!")
    }

    @Test("updateUser — username/password를 JSON 바디로 싣는다")
    func updateUserCarriesFields() throws {
        let target = UserAPITarget.updateUser(username: "도연", password: "new-secret!")

        let body = try #require(target.task.jsonBody(as: UpdateUserRequestDTO.self), "task가 .jsonEncodable이 아님")
        #expect(body.username == "도연")
        #expect(body.password == "new-secret!")
    }

    /// RefreshTokenRequestDTO는 CodingKeys로 서버가 기대하는 "Authorization" 필드명에 매핑된다.
    /// 이 키가 틀어지면 갱신이 조용히 실패하고 전 화면이 강제 로그아웃되므로 인코딩 결과까지 검증한다.
    @Test("refreshToken — 바디를 Authorization 키로 인코딩한다")
    func refreshTokenUsesAuthorizationBodyKey() throws {
        let target = UserAPITarget.refreshToken(refreshToken: "refresh-token-value")

        let body = try #require(target.task.jsonBody(as: RefreshTokenRequestDTO.self), "task가 .jsonEncodable이 아님")
        #expect(body.refreshToken == "refresh-token-value")

        let encoded = try JSONEncoder().encode(body)
        let json = try #require(JSONSerialization.jsonObject(with: encoded) as? NSDictionary)
        #expect(json == ["Authorization": "refresh-token-value"])
    }

    // MARK: - headers

    @Test("모든 케이스가 JSON 기본 헤더를 사용한다")
    func allCasesUseJSONHeader() {
        let targets: [UserAPITarget] = [
            .join(loginId: "dodle", password: "pw", username: "도연"),
            .login(loginId: "dodle", password: "pw"),
            .updateUser(username: "도연", password: "pw"),
            .getUser,
            .deleteUser,
            .logout,
            .refreshToken(refreshToken: "refresh-token-value")
        ]

        for target in targets {
            #expect(target.headers == ["Content-Type": "application/json"])
        }
    }
}
