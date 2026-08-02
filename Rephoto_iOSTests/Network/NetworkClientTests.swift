//
//  NetworkClientTests.swift
//  Rephoto_iOSTests
//
//  동시성 코어(actor NetworkClient)의 동작 검증.
//  - Bearer 토큰 주입 / 공개 경로 예외
//  - 401 → 토큰 갱신 → 재시도
//  - thundering-herd 방지(동시 401에도 갱신 1회)
//

import Foundation
import Testing
@testable import Rephoto_iOS

extension StubURLProtocolSuites {

    @Suite("NetworkClient")
    struct NetworkClientTests {

        // MARK: - Helpers

        private func makeClient(
            tokenStore: TokenStore = MockTokenStore(),
            refreshService: TokenRefreshService = MockTokenRefreshService(),
            maxRetryCount: Int = 1
        ) -> NetworkClient {
            StubURLProtocol.reset()
            return NetworkClient(
                session: StubURLProtocol.session(),
                tokenStore: tokenStore,
                refreshService: refreshService,
                maxRetryCount: maxRetryCount
            )
        }

        private func request(path: String, method: String = "GET") -> URLRequest {
            var req = URLRequest(url: URL(string: "https://api.test\(path)")!)
            req.httpMethod = method
            return req
        }

        private static func response(_ url: URL?, _ code: Int) -> HTTPURLResponse {
            HTTPURLResponse(
                url: url ?? URL(string: "https://api.test")!,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
        }

        // MARK: - 토큰 주입

        @Test("인증 필요 경로엔 저장된 access token이 Bearer 헤더로 주입된다")
        func injectsBearerTokenOnProtectedPath() async throws {
            let store = MockTokenStore(accessToken: "abc-access", refreshToken: "r")
            let client = makeClient(tokenStore: store)
            StubURLProtocol.handler = { req in (Self.response(req.url, 200), Data("{}".utf8)) }

            _ = try await client.request(request(path: "/photos"))

            let captured = try #require(StubURLProtocol.recordedRequests.first)
            #expect(captured.value(forHTTPHeaderField: "Authorization") == "Bearer abc-access")
        }

        @Test("공개 경로(/login)엔 토큰을 주입하지 않는다")
        func doesNotInjectTokenOnPublicPath() async throws {
            let store = MockTokenStore(accessToken: "abc-access", refreshToken: "r")
            let client = makeClient(tokenStore: store)
            StubURLProtocol.handler = { req in (Self.response(req.url, 200), Data("{}".utf8)) }

            _ = try await client.request(request(path: "/login", method: "POST"))

            let captured = try #require(StubURLProtocol.recordedRequests.first)
            #expect(captured.value(forHTTPHeaderField: "Authorization") == nil)
        }

        // MARK: - 성공 / 에러

        @Test("2xx 응답이면 데이터와 응답을 그대로 반환한다")
        func returnsDataAndResponseOnSuccess() async throws {
            let client = makeClient()
            let payload = Data(#"{"value":42}"#.utf8)
            StubURLProtocol.handler = { req in (Self.response(req.url, 200), payload) }

            let (data, response) = try await client.request(request(path: "/photos"))

            #expect(data == payload)
            #expect(response.statusCode == 200)
        }

        @Test("2xx도 401도 아닌 응답은 NetworkError.httpError로 던진다")
        func throwsHttpErrorOnServerError() async {
            let client = makeClient()
            StubURLProtocol.handler = { req in (Self.response(req.url, 500), Data("boom".utf8)) }

            await #expect(throws: NetworkError.httpError(statusCode: 500, data: Data("boom".utf8))) {
                _ = try await client.request(self.request(path: "/photos"))
            }
        }

        // MARK: - 401 → 토큰 갱신

        @Test("401 후 토큰 갱신이 성공하면 새 토큰으로 재시도해 성공한다. 갱신은 1회만")
        func refreshesOnceAndRetriesWithNewToken() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = SpyRefreshService(success: TokenPair(accessToken: "new", refreshToken: "r2"))
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in
                let authorized = req.value(forHTTPHeaderField: "Authorization") == "Bearer new"
                return (Self.response(req.url, authorized ? 200 : 401), Data("{}".utf8))
            }

            let (_, response) = try await client.request(request(path: "/photos"))

            #expect(response.statusCode == 200)
            let refreshCount = await refresh.count()
            #expect(refreshCount == 1)
            let savedAccess = await store.getAccessToken()
            #expect(savedAccess == "new", "갱신된 토큰이 저장소에 반영돼야 한다")
        }

        @Test("401 후 갱신이 실패하면 unauthorized를 던지고 onRefreshFailed 콜백이 호출된다")
        func firesCallbackWhenRefreshFails() async throws {
            let refresh = SpyRefreshService(success: nil) // 실패
            let client = makeClient(refreshService: refresh)
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }

            await confirmation("갱신 실패 시 onRefreshFailed 호출") { refreshFailed in
                await client.setOnRefreshFailed { refreshFailed() }

                await #expect(throws: NetworkError.unauthorized) {
                    _ = try await client.request(self.request(path: "/photos"))
                }
            }
        }

        @Test("갱신은 성공해도 서버가 계속 401이면, 재시도 한도 초과 후 unauthorized와 콜백")
        func exhaustsRetryOnPersistent401() async throws {
            let refresh = SpyRefreshService(success: TokenPair(accessToken: "new", refreshToken: "r2"))
            let client = makeClient(refreshService: refresh, maxRetryCount: 1)
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) } // 항상 401

            await confirmation("재시도 한도 초과 시 onRefreshFailed 호출") { refreshFailed in
                await client.setOnRefreshFailed { refreshFailed() }

                await #expect(throws: NetworkError.unauthorized) {
                    _ = try await client.request(self.request(path: "/photos"))
                }
            }

            let refreshCount = await refresh.count()
            #expect(refreshCount == 1, "재시도 한도 안에서 갱신은 1회만 시도된다")
        }

        // MARK: - ⭐ Thundering-herd 방지

        @Test("동시에 20개 요청이 모두 401을 받아도 토큰 갱신은 정확히 1회만 수행된다")
        func refreshesExactlyOnceUnderConcurrent401() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            // 갱신에 지연을 줘서 모든 동시 요청이 먼저 401을 받고 갱신 Task에 합류하도록 한다.
            let refresh = SpyRefreshService(
                success: TokenPair(accessToken: "new", refreshToken: "r2"),
                delay: .milliseconds(100)
            )
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in
                let authorized = req.value(forHTTPHeaderField: "Authorization") == "Bearer new"
                return (Self.response(req.url, authorized ? 200 : 401), Data("{}".utf8))
            }

            let req = request(path: "/photos")
            let requestCount = 20

            let successCount = try await withThrowingTaskGroup(of: Int.self) { group in
                for _ in 0..<requestCount {
                    group.addTask {
                        let (_, response) = try await client.request(req)
                        return response.statusCode
                    }
                }
                var oks = 0
                for try await code in group where code == 200 { oks += 1 }
                return oks
            }

            #expect(successCount == requestCount, "모든 동시 요청이 결국 성공해야 한다")
            let refreshCount = await refresh.count()
            #expect(refreshCount == 1, "동시 401에도 토큰 갱신은 단 1회여야 한다 (thundering-herd 방지)")
        }

        /// 갱신 Task는 하나로 합쳐지지만 그 실패는 대기하던 요청 전원에게 전달된다.
        /// 각자 콜백을 부르면 강제 로그아웃 통지가 요청 수만큼 나간다.
        @Test("동시 401에서 갱신이 실패해도 onRefreshFailed 통지는 1회만 나간다")
        func notifiesRefreshFailureOnceUnderConcurrent401() async throws {
            // 지연을 줘서 모든 동시 요청이 먼저 401을 받고 같은 갱신 Task에 합류하도록 한다.
            let refresh = SpyRefreshService(success: nil, delay: .milliseconds(100))
            let client = makeClient(refreshService: refresh)
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }

            let counter = CallCounter()
            await client.setOnRefreshFailed { Task { await counter.increment() } }

            let req = request(path: "/photos")
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<20 {
                    group.addTask { _ = try? await client.request(req) }
                }
            }

            // 콜백이 Task로 감싸여 있으므로 카운트가 반영될 여지를 준다.
            try await Task.sleep(for: .milliseconds(100))

            let notifyCount = await counter.value()
            #expect(notifyCount == 1, "동시 401 20건이 같은 갱신 실패를 공유해도 통지는 1회여야 한다")
            let refreshCount = await refresh.count()
            #expect(refreshCount == 1, "갱신 시도 자체도 1회여야 한다")
        }

        /// 통지를 1회로 접되, 세션이 되살아나면 다음 만료 때 다시 울려야 한다.
        @Test("갱신에 성공해 세션이 되살아나면 다음 갱신 실패는 다시 통지된다")
        func notifiesAgainAfterSessionRecovers() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = ScriptedRefreshService(results: [
                TokenPair(accessToken: "new", refreshToken: "r2"), // 1회차: 성공
                nil                                                // 2회차: 실패
            ])
            let client = makeClient(tokenStore: store, refreshService: refresh)

            let counter = CallCounter()
            await client.setOnRefreshFailed { Task { await counter.increment() } }

            // 1라운드: 401 → 갱신 성공 → 재시도 성공. 통지 없음.
            StubURLProtocol.handler = { req in
                let authorized = req.value(forHTTPHeaderField: "Authorization") == "Bearer new"
                return (Self.response(req.url, authorized ? 200 : 401), Data("{}".utf8))
            }
            _ = try await client.request(request(path: "/photos"))

            try await Task.sleep(for: .milliseconds(50))
            let afterRecovery = await counter.value()
            #expect(afterRecovery == 0, "갱신이 성공했으면 통지는 없어야 한다")

            // 2라운드: 다시 401 → 이번엔 갱신 실패 → 통지가 나가야 한다.
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }
            await #expect(throws: NetworkError.unauthorized) {
                _ = try await client.request(self.request(path: "/photos"))
            }

            try await Task.sleep(for: .milliseconds(50))
            let afterFailure = await counter.value()
            #expect(afterFailure == 1, "세션이 되살아난 뒤의 갱신 실패는 다시 통지돼야 한다")
        }

        // MARK: - logout

        @Test("logout은 저장된 토큰을 삭제하고 로그인 상태를 false로 만든다")
        func logoutClearsStoredTokens() async throws {
            let store = MockTokenStore(accessToken: "a", refreshToken: "r")
            let client = makeClient(tokenStore: store)
            let before = await client.isLoggedIn()
            #expect(before)

            try await client.logout()

            let after = await client.isLoggedIn()
            #expect(!after)
            let access = await store.getAccessToken()
            #expect(access == nil)
        }
    }
}

// MARK: - Test Doubles

/// 호출 횟수를 세는 토큰 갱신 서비스. success가 nil이면 실패를 던진다.
actor SpyRefreshService: TokenRefreshService {
    private(set) var callCount = 0
    private let newTokens: TokenPair?
    private let delay: Duration

    init(success: TokenPair?, delay: Duration = .zero) {
        self.newTokens = success
        self.delay = delay
    }

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        callCount += 1
        if delay > .zero { try? await Task.sleep(for: delay) }
        guard let newTokens else { throw NetworkError.unauthorized }
        return newTokens
    }

    func count() -> Int { callCount }
}



/// 호출마다 다른 결과를 내는 토큰 갱신 서비스. nil이면 실패를 던진다.
/// 대본을 다 쓰면 마지막 결과를 반복한다.
actor ScriptedRefreshService: TokenRefreshService {
    private let results: [TokenPair?]
    private var index = 0

    init(results: [TokenPair?]) {
        self.results = results
    }

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        let result = results[min(index, results.count - 1)]
        index += 1
        guard let result else { throw NetworkError.unauthorized }
        return result
    }
}

/// onRefreshFailed 호출 횟수를 세는 카운터.
/// 콜백이 @Sendable 클로저라 actor로 감싸 경합 없이 집계한다.
actor CallCounter {
    private var count = 0

    func increment() { count += 1 }
    func value() -> Int { count }
}
