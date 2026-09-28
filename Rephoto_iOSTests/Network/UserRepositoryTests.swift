//
//  UserRepositoryTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 9/26/26.
//
//  로그아웃 시 로컬 토큰 정리 검증.
//  서버 호출이 실패해도 토큰이 남으면 다음 실행 때 로그아웃한 계정으로 자동 로그인된다.
//

import Foundation
import Testing
@testable import Rephoto_iOS

extension StubURLProtocolSuites {

    @Suite("UserRepository")
    struct UserRepositoryTests {

        // MARK: - Helpers

        private func makeSUT(tokenStore: MockTokenStore) -> (UserRepository, NetworkClient) {
            StubURLProtocol.reset()
            let networkClient = NetworkClient(
                session: StubURLProtocol.session(),
                tokenStore: tokenStore,
                refreshService: MockTokenRefreshService()
            )
            let adapter = NetworkAdapter(
                networkClient: networkClient,
                baseURL: URL(string: "https://api.test")!
            )
            return (UserRepository(adapter: adapter, networkClient: networkClient), networkClient)
        }

        private static func response(_ url: URL?, _ code: Int) -> HTTPURLResponse {
            HTTPURLResponse(
                url: url ?? URL(string: "https://api.test")!,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
        }

        // MARK: - logout

        @Test("서버 로그아웃이 성공하면 저장된 토큰을 삭제한다")
        func logoutClearsTokensOnServerSuccess() async throws {
            let store = MockTokenStore(accessToken: "a", refreshToken: "r")
            let (sut, _) = makeSUT(tokenStore: store)
            StubURLProtocol.handler = { req in (Self.response(req.url, 200), Data("{}".utf8)) }

            try await sut.logout()

            let hasTokens = await sut.hasTokens()
            #expect(hasTokens == false)
        }

        @Test("서버 로그아웃이 실패해도(오프라인) 저장된 토큰은 삭제된다")
        func logoutClearsTokensEvenWhenServerFails() async throws {
            let store = MockTokenStore(accessToken: "a", refreshToken: "r")
            let (sut, _) = makeSUT(tokenStore: store)
            StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

            try await sut.logout()

            let hasTokens = await sut.hasTokens()
            #expect(hasTokens == false, "서버 호출 실패가 로컬 토큰 삭제를 막으면 안 된다")
            let refresh = await store.getRefreshToken()
            #expect(refresh == nil)
        }
    }
}
