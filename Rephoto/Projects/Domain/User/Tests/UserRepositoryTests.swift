//
//  UserRepositoryTests.swift
//  UserDomainTests
//
//  Created by Doyeon Kim on 9/26/26.
//

import Foundation
import Synchronization
import Testing
import NetworkAdapter
import NetworkAdapterTesting
import RephotoFoundation
import UserDomainInterface
@testable import UserDomain

/// `decode`를 가로채 호출 스레드를 기록한다. MainActor 테스트 안에 두면 격리가 따라붙으므로 파일 범위에 둔다.
private final class RecordingDecoder: JSONDecoder, @unchecked Sendable {
    let decodedOnMainThread = Mutex<Bool?>(nil)

    override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        decodedOnMainThread.withLock { $0 = Thread.isMainThread }
        return try super.decode(type, from: data)
    }
}

private struct RejectingRefreshService: TokenRefreshService {
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        throw NetworkError.unauthorized
    }
}

extension StubURLProtocolSuites {

    @Suite("UserRepository")
    struct UserRepositoryTests {

        private func makeSUT(
            tokenStore: MockTokenStore = MockTokenStore(),
            refreshService: TokenRefreshService = MockTokenRefreshService(),
            decoder: JSONDecoder = JSONDecoder()
        ) -> UserRepository {
            StubURLProtocol.reset()
            let networkClient = NetworkClient(
                session: StubURLProtocol.session(),
                tokenStore: tokenStore,
                refreshService: refreshService
            )
            let adapter = NetworkAdapter(networkClient: networkClient, baseURL: URL(string: "https://api.test")!)
            return UserRepository(adapter: adapter, networkClient: networkClient, decoder: decoder)
        }

        private static func ok(_ request: URLRequest, body: String) -> (HTTPURLResponse, Data) {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }

        private static let tokenBody = #"{"accessToken":"new-access","refreshToken":"new-refresh"}"#
        private static let userBody = #"{"userId":1,"loginId":7,"name":"도연"}"#

        // MARK: - login

        @Test("login — POST /login에 자격증명을 싣고 응답 토큰을 저장한다")
        func loginSavesTokens() async throws {
            let store = MockTokenStore(accessToken: nil, refreshToken: nil)
            let sut = makeSUT(tokenStore: store)
            StubURLProtocol.handler = { request in Self.ok(request, body: Self.tokenBody) }

            try await sut.login(loginId: "dodle", password: "secret!")

            let request = try #require(StubURLProtocol.recordedRequests.first)
            #expect(request.url?.path == "/login")
            #expect(request.httpMethod == "POST")
            let body = try JSONSerialization.jsonObject(with: request.bodyData) as? NSDictionary
            #expect(body == ["loginId": "dodle", "password": "secret!"])
            #expect(store.load() == TokenPair(accessToken: "new-access", refreshToken: "new-refresh"))
            #expect(await sut.hasTokens())
        }

        @Test("login — 응답이 토큰 형태가 아니면 디코딩 에러를 던지고 토큰을 저장하지 않는다")
        func loginWithInvalidResponseSavesNothing() async throws {
            let store = MockTokenStore(accessToken: nil, refreshToken: nil)
            let sut = makeSUT(tokenStore: store)
            StubURLProtocol.handler = { request in Self.ok(request, body: #"{"unexpected":true}"#) }

            await #expect(throws: DecodingError.self) {
                try await sut.login(loginId: "dodle", password: "secret!")
            }

            #expect(store.load() == nil)
        }

        @Test("login — 메인 액터에서 호출해도 디코딩은 메인 스레드 밖에서 실행된다")
        @MainActor
        func loginDecodesOutsideMainActor() async throws {
            MainActor.preconditionIsolated()
            let decoder = RecordingDecoder()
            let sut = makeSUT(decoder: decoder)
            StubURLProtocol.handler = { request in Self.ok(request, body: Self.tokenBody) }

            try await sut.login(loginId: "dodle", password: "secret!")

            #expect(decoder.decodedOnMainThread.withLock { $0 } == false)
        }

        // MARK: - fetchUser

        @Test("fetchUser — GET /users 응답을 도메인 모델로 매핑한다")
        func fetchUserMapsResponse() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in Self.ok(request, body: Self.userBody) }

            let user = try await sut.fetchUser()

            let request = try #require(StubURLProtocol.recordedRequests.first)
            #expect(request.url?.path == "/users")
            #expect(request.httpMethod == "GET")
            #expect(user == UserInfo(userId: 1, loginId: 7, name: "도연"))
        }

        @Test("fetchUser — 메인 액터에서 호출해도 디코딩은 메인 스레드 밖에서 실행된다")
        @MainActor
        func fetchUserDecodesOutsideMainActor() async throws {
            MainActor.preconditionIsolated()
            let decoder = RecordingDecoder()
            let sut = makeSUT(decoder: decoder)
            StubURLProtocol.handler = { request in Self.ok(request, body: Self.userBody) }

            _ = try await sut.fetchUser()

            #expect(decoder.decodedOnMainThread.withLock { $0 } == false)
        }

        // MARK: - logout

        @Test("서버 로그아웃이 성공하면 저장된 토큰을 삭제한다")
        func logoutClearsTokensOnServerSuccess() async throws {
            let store = MockTokenStore(accessToken: "a", refreshToken: "r")
            let sut = makeSUT(tokenStore: store)
            StubURLProtocol.handler = { request in Self.ok(request, body: "{}") }

            try await sut.logout()

            #expect(await sut.hasTokens() == false)
        }

        @Test("서버 로그아웃이 실패해도(오프라인) 저장된 토큰은 삭제된다")
        func logoutClearsTokensEvenWhenServerFails() async throws {
            let store = MockTokenStore(accessToken: "a", refreshToken: "r")
            let sut = makeSUT(tokenStore: store)
            StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

            try await sut.logout()

            #expect(await sut.hasTokens() == false, "서버 호출 실패가 로컬 토큰 삭제를 막으면 안 된다")
            #expect(store.load() == nil)
        }

        // MARK: - setOnRefreshFailed

        @Test("setOnRefreshFailed — 등록한 뒤 토큰 갱신이 거절되면 핸들러가 한 번 호출되고 토큰이 삭제된다")
        func refreshFailureCallsRegisteredHandler() async throws {
            let store = MockTokenStore(accessToken: "a", refreshToken: "r")
            let sut = makeSUT(tokenStore: store, refreshService: RejectingRefreshService())
            StubURLProtocol.handler = { request in
                (HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!, Data("{}".utf8))
            }

            await confirmation("갱신 실패 시 핸들러 호출") { refreshFailed in
                await sut.setOnRefreshFailed { refreshFailed() }

                await #expect(throws: NetworkError.unauthorized) {
                    _ = try await sut.fetchUser()
                }
            }

            #expect(store.load() == nil)
        }
    }
}
