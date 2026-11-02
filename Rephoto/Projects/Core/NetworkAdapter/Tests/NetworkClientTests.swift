//
//  NetworkClientTests.swift
//  NetworkAdapterTests
//
//  동시성 코어(actor NetworkClient)의 동작 검증.
//  - Bearer 토큰 주입 / 공개 경로 예외
//  - 401 → 토큰 갱신 → 재시도
//  - thundering-herd 방지(동시 401에도 갱신 1회)
//

import Foundation
import Testing
import RephotoFoundation
import NetworkAdapterTesting
@testable import NetworkAdapter

extension StubURLProtocolSuites {

    @Suite("NetworkClient")
    struct NetworkClientTests {

        // MARK: - Helpers

        private func makeClient(
            tokenStore: TokenStore = MockTokenStore(),
            refreshService: TokenRefreshService = MockTokenRefreshService(),
            authPolicy: AuthenticationPolicy = DefaultAuthenticationPolicy(),
            maxRetryCount: Int = 1
        ) -> NetworkClient {
            StubURLProtocol.reset()
            return NetworkClient(
                session: StubURLProtocol.session(),
                tokenStore: tokenStore,
                refreshService: refreshService,
                authPolicy: authPolicy,
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
            let savedAccess = store.load()?.accessToken
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

        /// 화면만 로그아웃되고 토큰이 남으면 재실행 시 자동 로그인 → 401 → 로그인 화면으로 튕긴다.
        @Test("갱신 실패로 세션이 끝나면 저장된 토큰을 삭제한다")
        func clearsStoredTokensWhenRefreshFails() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = SpyRefreshService(success: nil) // 실패
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }

            await #expect(throws: NetworkError.unauthorized) {
                _ = try await client.request(self.request(path: "/photos"))
            }

            let loggedIn = await client.isLoggedIn()
            #expect(loggedIn == false)
            let refreshToken = store.load()?.refreshToken
            #expect(refreshToken == nil, "refresh token까지 삭제돼야 재실행 시 자동 로그인되지 않는다")
        }

        @Test("갱신 서버가 401로 거절하면 세션 종료로 처리해 토큰을 삭제하고 통지한다")
        func endsSessionWhenRefreshRejectedWith401() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = FailingRefreshService(error: NetworkError.httpError(statusCode: 401, data: Data()))
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }

            let counter = CallCounter()
            await client.setOnRefreshFailed { counter.increment() }

            await #expect(throws: NetworkError.unauthorized) {
                _ = try await client.request(self.request(path: "/photos"))
            }

            #expect(counter.value == 1)
            let refreshToken = store.load()?.refreshToken
            #expect(refreshToken == nil)
        }

        /// 서버 장애 한 번에 전원이 로그아웃되면 안 된다 — 세션은 여전히 유효할 수 있다.
        @Test("갱신이 5xx로 실패하면 토큰을 유지하고 통지 없이 httpError를 던진다")
        func keepsSessionWhenRefreshFailsTransiently() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = FailingRefreshService(error: NetworkError.httpError(statusCode: 500, data: Data()))
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }

            let counter = CallCounter()
            await client.setOnRefreshFailed { counter.increment() }

            await #expect(throws: NetworkError.httpError(statusCode: 500, data: Data())) {
                _ = try await client.request(self.request(path: "/photos"))
            }

            #expect(counter.value == 0, "일시적 실패는 세션 종료 통지를 보내면 안 된다")
            let refreshToken = store.load()?.refreshToken
            #expect(refreshToken == "r", "일시적 실패로 토큰을 지우면 안 된다")
        }

        // MARK: - ⭐ Thundering-herd 방지

        @Test("동시에 20개 요청이 모두 401을 받아도 토큰 갱신은 정확히 1회만 수행된다")
        func refreshesExactlyOnceUnderConcurrent401() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let requestCount = 20
            // 모든 요청이 401을 판정하고 갱신 Task에 합류한 뒤에야 갱신이 끝나도록 횟수로 순서를 고정한다.
            let allUnauthorized = ArrivalLatch(expected: requestCount)
            let refresh = SpyRefreshService(
                success: TokenPair(accessToken: "new", refreshToken: "r2"),
                waitFor: allUnauthorized
            )
            let client = makeClient(
                tokenStore: store,
                refreshService: refresh,
                authPolicy: LatchingAuthenticationPolicy(latch: allUnauthorized)
            )
            StubURLProtocol.handler = { req in
                let authorized = req.value(forHTTPHeaderField: "Authorization") == "Bearer new"
                return (Self.response(req.url, authorized ? 200 : 401), Data("{}".utf8))
            }

            let req = request(path: "/photos")

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
            let requestCount = 20
            // 모든 요청이 401을 판정하고 같은 갱신 Task에 합류한 뒤에야 갱신이 실패하도록 횟수로 고정한다.
            let allUnauthorized = ArrivalLatch(expected: requestCount)
            let refresh = SpyRefreshService(success: nil, waitFor: allUnauthorized)
            let client = makeClient(
                refreshService: refresh,
                authPolicy: LatchingAuthenticationPolicy(latch: allUnauthorized)
            )
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }

            let counter = CallCounter()
            await client.setOnRefreshFailed { counter.increment() }

            let req = request(path: "/photos")
            let unauthorizedCount = await withTaskGroup(of: Bool.self) { group in
                for _ in 0..<requestCount {
                    group.addTask {
                        do {
                            _ = try await client.request(req)
                            return false
                        } catch NetworkError.unauthorized {
                            return true
                        } catch {
                            return false
                        }
                    }
                }
                var count = 0
                for await isUnauthorized in group where isUnauthorized { count += 1 }
                return count
            }

            #expect(unauthorizedCount == requestCount, "대기하던 요청 전원이 unauthorized로 끝나야 한다")
            // 통지는 요청이 throw하기 전에 끝나므로, 그룹이 끝난 시점에 카운트는 확정이다.
            #expect(counter.value == 1, "동시 401 20건이 같은 갱신 실패를 공유해도 통지는 1회여야 한다")
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
            await client.setOnRefreshFailed { counter.increment() }

            // 1라운드: 401 → 갱신 성공 → 재시도 성공. 통지 없음.
            StubURLProtocol.handler = { req in
                let authorized = req.value(forHTTPHeaderField: "Authorization") == "Bearer new"
                return (Self.response(req.url, authorized ? 200 : 401), Data("{}".utf8))
            }
            _ = try await client.request(request(path: "/photos"))

            #expect(counter.value == 0, "갱신이 성공했으면 통지는 없어야 한다")

            // 2라운드: 다시 401 → 이번엔 갱신 실패 → 통지가 나가야 한다.
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }
            await #expect(throws: NetworkError.unauthorized) {
                _ = try await client.request(self.request(path: "/photos"))
            }

            #expect(counter.value == 1, "세션이 되살아난 뒤의 갱신 실패는 다시 통지돼야 한다")
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
            #expect(after == false)
            let access = store.load()?.accessToken
            #expect(access == nil)
        }

        @Test(
            "세션 전환은 이전 갱신을 기다리지 않고, 뒤늦은 성공·실패는 현재 세션에 영향을 주지 않는다",
            .timeLimit(.minutes(1)),
            arguments: [true, false], [true, false]
        )
        func sessionSwitchDiscardsPendingRefresh(refreshSucceeds: Bool, logsOut: Bool) async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let stale = TokenPair(accessToken: "stale", refreshToken: "stale-r")
            let refresh = GatedRefreshService(success: refreshSucceeds ? stale : nil)
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in
                let isOldToken = req.value(forHTTPHeaderField: "Authorization") == "Bearer old"
                return (Self.response(req.url, isOldToken ? 401 : 200), Data())
            }
            let counter = CallCounter()
            await client.setOnRefreshFailed { counter.increment() }

            let req = request(path: "/photos")
            let inFlight = Task { try await client.request(req) }
            await refresh.gate.waitUntilEntered()

            // 취소에 협조하지 않는 갱신을 풀기 전에 세션 전환이 끝나야 한다.
            if logsOut {
                try await client.logout()
            } else {
                try await client.saveTokens(accessToken: "login", refreshToken: "login-r")
            }
            let expected = logsOut ? nil : TokenPair(accessToken: "login", refreshToken: "login-r")
            #expect(store.load() == expected)
            await refresh.gate.release()

            await #expect(throws: CancellationError.self) {
                _ = try await inFlight.value
            }
            #expect(store.load() == expected)
            #expect(counter.value == 0, "이전 세션의 실패로 현재 세션을 종료하면 안 된다")
            #expect(StubURLProtocol.recordedRequests.count == 1, "이전 요청을 새 세션으로 재시도하면 안 된다")
        }

        @Test(
            "세션 전환 뒤 도착한 이전 HTTP 응답은 성공·401 모두 취소로 끝난다",
            .timeLimit(.minutes(1)),
            arguments: [200, 401], [true, false]
        )
        func sessionSwitchDiscardsPendingResponse(statusCode: Int, logsOut: Bool) async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = SpyRefreshService(success: TokenPair(accessToken: "new", refreshToken: "new-r"))
            let client = makeClient(tokenStore: store, refreshService: refresh)
            let requestStarted = ArrivalLatch(expected: 1)
            let releaseResponse = DispatchSemaphore(value: 0)
            StubURLProtocol.handler = { req in
                if req.value(forHTTPHeaderField: "Authorization") == "Bearer old" {
                    requestStarted.arrive()
                    releaseResponse.wait()
                    return (Self.response(req.url, statusCode), Data())
                }
                return (Self.response(req.url, 200), Data())
            }
            defer { releaseResponse.signal() }
            let counter = CallCounter()
            await client.setOnRefreshFailed { counter.increment() }

            let req = request(path: "/photos", method: "POST")
            let inFlight = Task { try await client.request(req) }
            await requestStarted.wait()
            if logsOut {
                try await client.logout()
            } else {
                try await client.saveTokens(accessToken: "login", refreshToken: "login-r")
            }
            releaseResponse.signal()

            await #expect(throws: CancellationError.self) {
                _ = try await inFlight.value
            }
            let refreshCount = await refresh.count()
            #expect(refreshCount == 0, "이전 요청의 401로 현재 세션을 갱신하면 안 된다")
            #expect(counter.value == 0)
            #expect(StubURLProtocol.recordedRequests.count == 1)
            let expected = logsOut ? nil : TokenPair(accessToken: "login", refreshToken: "login-r")
            #expect(store.load() == expected)
        }

        @Test("공개 경로의 401은 갱신·통지 없이 httpError로 돌려준다")
        func publicPath401IsReturnedAsHttpError() async throws {
            let store = MockTokenStore(accessToken: "a", refreshToken: "r")
            let refresh = SpyRefreshService(success: TokenPair(accessToken: "new", refreshToken: "new-r"))
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("wrong".utf8)) }
            let counter = CallCounter()
            await client.setOnRefreshFailed { counter.increment() }

            await #expect(throws: NetworkError.httpError(statusCode: 401, data: Data("wrong".utf8))) {
                _ = try await client.request(self.request(path: "/login", method: "POST"))
            }

            let refreshCount = await refresh.count()
            #expect(refreshCount == 0)
            #expect(counter.value == 0)
            #expect(store.load() == TokenPair(accessToken: "a", refreshToken: "r"))
        }

        @Test("세션 전환 뒤 도착한 공개 경로 응답은 취소하지 않는다", .timeLimit(.minutes(1)), arguments: [true, false])
        func sessionSwitchKeepsPendingPublicResponse(logsOut: Bool) async throws {
            let client = makeClient()
            let requestStarted = ArrivalLatch(expected: 1)
            let releaseResponse = DispatchSemaphore(value: 0)
            StubURLProtocol.handler = { req in
                requestStarted.arrive()
                releaseResponse.wait()
                return (Self.response(req.url, 200), Data())
            }
            defer { releaseResponse.signal() }

            let req = request(path: "/join", method: "POST")
            let inFlight = Task { try await client.request(req) }
            await requestStarted.wait()
            if logsOut {
                try await client.logout()
            } else {
                try await client.saveTokens(accessToken: "login", refreshToken: "login-r")
            }
            releaseResponse.signal()

            let (_, response) = try await inFlight.value
            #expect(response.statusCode == 200)
        }

        @Test("이전 갱신이 끝나도 현재 세션의 진행 중인 갱신을 공유한다", .timeLimit(.minutes(1)))
        func staleRefreshCompletionKeepsCurrentRefreshTask() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "old-r")
            let oldRefresh = GatedRefreshService(success: TokenPair(accessToken: "stale", refreshToken: "stale-r"))
            let newTokens = TokenPair(accessToken: "new", refreshToken: "new-r")
            let currentRefresh = GatedRefreshService(success: newTokens)
            let allUnauthorized = ArrivalLatch(expected: 3)
            let client = makeClient(
                tokenStore: store,
                refreshService: SessionRefreshService(previous: oldRefresh, current: currentRefresh),
                authPolicy: LatchingAuthenticationPolicy(latch: allUnauthorized)
            )
            StubURLProtocol.handler = { req in
                let authorized = req.value(forHTTPHeaderField: "Authorization") == "Bearer new"
                return (Self.response(req.url, authorized ? 200 : 401), Data())
            }

            let req = request(path: "/photos")
            let oldRequest = Task { try await client.request(req) }
            await oldRefresh.gate.waitUntilEntered()
            try await client.saveTokens(accessToken: "login", refreshToken: "login-r")

            let firstCurrentRequest = Task { try await client.request(req) }
            await currentRefresh.gate.waitUntilEntered()
            await oldRefresh.gate.release()
            await #expect(throws: CancellationError.self) {
                _ = try await oldRequest.value
            }

            let secondCurrentRequest = Task { try await client.request(req) }
            await allUnauthorized.wait()
            await currentRefresh.gate.release()
            let (_, firstResponse) = try await firstCurrentRequest.value
            let (_, secondResponse) = try await secondCurrentRequest.value

            #expect(firstResponse.statusCode == 200)
            #expect(secondResponse.statusCode == 200)
            #expect(currentRefresh.calls.value == 1, "이전 Task의 정리가 새 갱신 슬롯을 지우면 안 된다")
            #expect(store.load() == newTokens)
        }
    }
}

// MARK: - Test Doubles

/// 호출 횟수를 세는 토큰 갱신 서비스. success가 nil이면 실패를 던지고, waitFor 래치가 있으면 열릴 때까지 응답을 미룬다.
actor SpyRefreshService: TokenRefreshService {
    private(set) var callCount = 0
    private let newTokens: TokenPair?
    private let latch: ArrivalLatch?

    init(success: TokenPair?, waitFor latch: ArrivalLatch? = nil) {
        self.newTokens = success
        self.latch = latch
    }

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        callCount += 1
        if let latch { await latch.wait() }
        guard let newTokens else { throw NetworkError.unauthorized }
        return newTokens
    }

    func count() -> Int { callCount }
}

/// 401 판정 때 래치를 두드리는 인증 정책.
///
/// 판정은 NetworkClient actor 위에서 일어나고, 그 요청은 갱신 Task에 합류할 때까지 actor를 놓지 않는다.
/// URLProtocol 핸들러에서 세면 응답은 만들어졌지만 아직 actor에 돌아오지 않은 요청이 생겨 갱신이 두 번 일어난다.
struct LatchingAuthenticationPolicy: AuthenticationPolicy {
    let latch: ArrivalLatch
    private let base = DefaultAuthenticationPolicy()

    func requireAuthentication(_ request: URLRequest) -> Bool {
        base.requireAuthentication(request)
    }

    func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool {
        let unauthorized = base.isUnauthorizedResponse(response)
        if unauthorized { latch.arrive() }
        return unauthorized
    }
}

/// 정해진 횟수의 arrive()가 모이면 열리는 래치. arrive()는 동기 문맥에서 부르므로 락 기반.
final class ArrivalLatch: @unchecked Sendable {
    private let lock = NSLock()
    private let expected: Int
    private var arrived = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(expected: Int) {
        self.expected = expected
    }

    func arrive() {
        let toResume: [CheckedContinuation<Void, Never>] = lock.withLock {
            arrived += 1
            guard arrived >= expected else { return [] }
            defer { waiters.removeAll() }
            return waiters
        }
        toResume.forEach { $0.resume() }
    }

    func wait() async {
        await withCheckedContinuation { continuation in
            let isOpen: Bool = lock.withLock {
                if arrived >= expected { return true }
                waiters.append(continuation)
                return false
            }
            if isOpen { continuation.resume() }
        }
    }
}



/// 지정한 에러로 항상 실패하는 토큰 갱신 서비스. 실제 구현이 던지는 `NetworkError` 분기 검증용.
struct FailingRefreshService: TokenRefreshService {
    let error: Error

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        throw error
    }
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

/// 취소에 협조하지 않는 응답을 재현한다. release() 전에는 호출자를 재개하지 않는다.
actor TestGate {
    private var hasEntered = false
    private var isReleased = false
    private var enteredWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiters: [CheckedContinuation<Void, Never>] = []

    func hold() async {
        hasEntered = true
        enteredWaiter?.resume()
        enteredWaiter = nil
        guard !isReleased else { return }
        await withCheckedContinuation { releaseWaiters.append($0) }
    }

    func waitUntilEntered() async {
        if hasEntered { return }
        await withCheckedContinuation { enteredWaiter = $0 }
    }

    func release() {
        isReleased = true
        releaseWaiters.forEach { $0.resume() }
        releaseWaiters.removeAll()
    }
}

/// 게이트가 풀릴 때까지 응답을 붙잡아 두는 토큰 갱신 서비스.
struct GatedRefreshService: TokenRefreshService {
    let gate = TestGate()
    let calls = CallCounter()
    private let newTokens: TokenPair?

    init(success: TokenPair?) {
        self.newTokens = success
    }

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        calls.increment()
        await gate.hold()
        guard let newTokens else { throw NetworkError.unauthorized }
        return newTokens
    }
}

/// 이전 계정과 현재 계정의 갱신을 각각 다른 게이트로 제어한다.
struct SessionRefreshService: TokenRefreshService {
    let previous: GatedRefreshService
    let current: GatedRefreshService

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        if refreshToken == "old-r" {
            return try await previous.refresh(refreshToken)
        }
        return try await current.refresh(refreshToken)
    }
}

/// onRefreshFailed 호출 횟수를 세는 카운터.
///
/// actor가 아니라 락으로 감싼다. 콜백이 동기 클로저(`@Sendable () -> Void`)라
/// actor로 만들면 `Task { await ... }`로 넘겨야 하고, 그러면 집계 시점이 밀려
/// 검증 전에 sleep으로 기다리는 비결정적 테스트가 된다.
/// 락 기반이면 콜백 호출 즉시 집계되므로, 요청이 끝난 시점에 카운트가 확정된다.
final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() { lock.withLock { count += 1 } }
    var value: Int { lock.withLock { count } }
}
