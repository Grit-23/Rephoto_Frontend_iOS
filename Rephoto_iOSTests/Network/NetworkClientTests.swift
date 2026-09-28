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
            let refreshToken = await store.getRefreshToken()
            #expect(refreshToken == nil, "refresh token까지 삭제돼야 재실행 시 자동 로그인되지 않는다")
        }

        @Test("갱신 서버가 401로 거절하면 세션 종료로 처리해 토큰을 삭제하고 통지한다")
        func endsSessionWhenRefreshRejectedWith401() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = FailingRefreshService(error: TokenRefreshError.serverError(statusCode: 401))
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }

            let counter = CallCounter()
            await client.setOnRefreshFailed { counter.increment() }

            await #expect(throws: NetworkError.unauthorized) {
                _ = try await client.request(self.request(path: "/photos"))
            }

            #expect(counter.value == 1)
            let refreshToken = await store.getRefreshToken()
            #expect(refreshToken == nil)
        }

        /// 서버 장애 한 번에 전원이 로그아웃되면 안 된다 — 세션은 여전히 유효할 수 있다.
        @Test("갱신이 5xx로 실패하면 토큰을 유지하고 통지 없이 httpError를 던진다")
        func keepsSessionWhenRefreshFailsTransiently() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = FailingRefreshService(error: TokenRefreshError.serverError(statusCode: 500))
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }

            let counter = CallCounter()
            await client.setOnRefreshFailed { counter.increment() }

            await #expect(throws: NetworkError.httpError(statusCode: 500, data: Data())) {
                _ = try await client.request(self.request(path: "/photos"))
            }

            #expect(counter.value == 0, "일시적 실패는 세션 종료 통지를 보내면 안 된다")
            let refreshToken = await store.getRefreshToken()
            #expect(refreshToken == "r", "일시적 실패로 토큰을 지우면 안 된다")
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
            await client.setOnRefreshFailed { counter.increment() }

            let req = request(path: "/photos")
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<20 {
                    group.addTask { _ = try? await client.request(req) }
                }
            }

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
            let access = await store.getAccessToken()
            #expect(access == nil)
        }

        /// 갱신 응답이 이미 도착해 session.data(for:)의 취소 관측 지점을 지나친 뒤 logout이 오는 창.
        /// 저장 직전의 checkCancellation이 저장을 건너뛰고 CancellationError를 전달하는지 검증한다.
        ///
        /// GatedRefreshService는 취소를 무시하고 신호가 올 때까지 응답을 붙잡아 둬,
        /// "응답은 왔지만 아직 저장 전" 상태에서 logout을 끼워 넣는 순서를 결정적으로 만든다.
        // 게이트는 신호가 없으면 영원히 기다린다. 갱신이 호출되지 않는 방향으로 회귀하면
        // 무한 대기가 되어 .serialized 컨테이너의 뒤 스위트까지 막히므로 시간 제한을 둔다(분 단위만 허용).
        @Test("갱신 응답 도착 후 logout이 오면 새 토큰을 저장하지 않는다", .timeLimit(.minutes(1)))
        func logoutDuringRefreshDoesNotResurrectTokens() async throws {
            let store = MockTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = GatedRefreshService(success: TokenPair(accessToken: "new", refreshToken: "r2"))
            let client = makeClient(tokenStore: store, refreshService: refresh)
            // 새 토큰이면 200. 항상 401로 두면 checkCancellation이 없어도 재시도 한도 초과 경로가
            // 토큰을 지워 버려, 아래 "저장소가 비어 있다" 단언이 변이를 잡지 못한다.
            StubURLProtocol.handler = { req in
                let authorized = req.value(forHTTPHeaderField: "Authorization") == "Bearer new"
                return (Self.response(req.url, authorized ? 200 : 401), Data("{}".utf8))
            }

            let req = request(path: "/photos")
            let inFlight = Task { try await client.request(req) }
            await refresh.gate.waitUntilEntered()

            // logout은 갱신 Task 종료를 기다리므로 별도 Task로 띄운다.
            // cancel()이 갱신 Task에 도달한 것을 확인한 뒤 응답을 풀어야 "취소된 뒤 도착한 응답" 순서가 된다.
            let logout = Task { try await client.logout() }
            await refresh.gate.waitUntilCancelled()
            await refresh.gate.release()
            try await logout.value

            await #expect(throws: CancellationError.self) {
                _ = try await inFlight.value
            }
            let access = await store.getAccessToken()
            #expect(access == nil, "logout 뒤 도착한 갱신 결과가 저장소를 되살리면 안 된다")
            let refreshToken = await store.getRefreshToken()
            #expect(refreshToken == nil)
            // 최초 401 1건만 나갔어야 한다. 저장이 됐다면 새 토큰으로 재시도가 한 번 더 기록된다.
            #expect(StubURLProtocol.recordedRequests.count == 1, "logout 뒤 새 토큰으로 재시도하면 안 된다")
        }

        /// checkCancellation을 통과해 저장 단계에 들어간 뒤 logout이 오는 창.
        /// logout이 갱신 Task 종료를 기다리지 않으면 clear가 먼저 실행되고 뒤늦은 save가 토큰을 되살린다.
        /// 저장을 게이트로 붙잡아 두고 그 사이에 logout을 끼워 넣어, clear가 save 뒤에 오는지 검증한다.
        @Test("저장 단계에서 logout이 오면 갱신 Task가 끝난 뒤 토큰을 지운다", .timeLimit(.minutes(1)))
        func logoutWaitsForInFlightSaveBeforeClearing() async throws {
            let store = GatedTokenStore(accessToken: "old", refreshToken: "r")
            let refresh = SpyRefreshService(success: TokenPair(accessToken: "new", refreshToken: "r2"))
            let client = makeClient(tokenStore: store, refreshService: refresh)
            StubURLProtocol.handler = { req in
                let authorized = req.value(forHTTPHeaderField: "Authorization") == "Bearer new"
                return (Self.response(req.url, authorized ? 200 : 401), Data("{}".utf8))
            }

            let req = request(path: "/photos")
            let inFlight = Task { try await client.request(req) }
            await store.saveGate.waitUntilEntered()

            let logout = Task { try await client.logout() }
            // logout이 cancel()까지 진행한 시점. 기다리는 구현이면 여기서 save 완료를 대기하고,
            // 기다리지 않는 구현이면 이미 clear()를 호출했다.
            await store.saveGate.waitUntilCancelled()
            await store.saveGate.release()
            try await logout.value
            // 재시도는 clear와 경합하므로 결과는 보지 않고 끝나기만 기다린다(늦은 clear 기록 방지).
            _ = try? await inFlight.value

            let events = await store.events
            #expect(events.first == "save", "clear는 진행 중인 save가 끝난 뒤여야 한다: \(events)")
            let access = await store.getAccessToken()
            #expect(access == nil, "logout이 끝난 뒤 토큰이 남으면 안 된다")
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



/// 지정한 에러로 항상 실패하는 토큰 갱신 서비스. 실제 구현이 던지는 `TokenRefreshError` 분기 검증용.
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

/// 진입을 알리고 release()가 올 때까지 호출자를 붙잡아 두는 게이트.
///
/// 붙잡힌 Task의 취소는 무시하되 관측만 한다. 실제 URLSession이라면 "응답을 이미 받아
/// 취소 확인 지점을 지난 뒤"에 해당하는 상태를 흉내 내고, 테스트는 waitUntilCancelled()로
/// logout의 cancel()이 도달한 시점을 잡아 그 뒤에 release()하는 순서를 결정적으로 만든다.
actor TestGate {
    private var hasEntered = false
    private var isReleased = false
    private var isCancelled = false
    private var enteredWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?
    private var cancelWaiter: CheckedContinuation<Void, Never>?

    /// 붙잡히는 쪽이 호출한다. release()까지 대기하며, 이미 풀렸으면 즉시 반환.
    func hold() async {
        hasEntered = true
        enteredWaiter?.resume()
        enteredWaiter = nil
        guard isReleased == false else { return }
        await withTaskCancellationHandler {
            await withCheckedContinuation { releaseWaiter = $0 }
        } onCancel: {
            Task { await self.markCancelled() }
        }
    }

    /// hold()가 호출될 때까지 기다린다. 이미 호출됐으면 즉시 반환.
    func waitUntilEntered() async {
        if hasEntered { return }
        await withCheckedContinuation { enteredWaiter = $0 }
    }

    /// 붙잡힌 Task가 취소될 때까지 기다린다. 이미 취소됐으면 즉시 반환.
    func waitUntilCancelled() async {
        if isCancelled { return }
        await withCheckedContinuation { cancelWaiter = $0 }
    }

    /// 붙잡아 둔 호출자를 풀어 준다.
    func release() {
        isReleased = true
        releaseWaiter?.resume()
        releaseWaiter = nil
    }

    private func markCancelled() {
        isCancelled = true
        cancelWaiter?.resume()
        cancelWaiter = nil
    }
}

/// 게이트가 풀릴 때까지 응답을 붙잡아 두는 토큰 갱신 서비스.
struct GatedRefreshService: TokenRefreshService {
    let gate = TestGate()
    private let newTokens: TokenPair

    init(success: TokenPair) {
        self.newTokens = success
    }

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        await gate.hold()
        return newTokens
    }
}

/// save를 게이트로 붙잡아 두고 save/clear 호출 순서를 기록하는 토큰 저장소.
actor GatedTokenStore: TokenStore {
    let saveGate = TestGate()
    private(set) var events: [String] = []
    private var access: String?
    private var refresh: String?

    init(accessToken: String?, refreshToken: String?) {
        self.access = accessToken
        self.refresh = refreshToken
    }

    func getAccessToken() async -> String? { access }
    func getRefreshToken() async -> String? { refresh }

    func save(accessToken: String, refreshToken: String) async throws {
        await saveGate.hold()
        access = accessToken
        refresh = refreshToken
        events.append("save")
    }

    func clear() async throws {
        access = nil
        refresh = nil
        events.append("clear")
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
