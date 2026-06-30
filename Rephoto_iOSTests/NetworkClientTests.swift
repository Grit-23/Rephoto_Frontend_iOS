//
//  NetworkClientTests.swift
//  Rephoto_iOSTests
//
//  동시성 코어(actor NetworkClient)의 동작 검증.
//  - Bearer 토큰 주입 / 공개 경로 예외
//  - 401 → 토큰 갱신 → 재시도
//  - thundering-herd 방지(동시 401에도 갱신 1회)
//

import XCTest
@testable import Rephoto_iOS

final class NetworkClientTests: XCTestCase {

    override func tearDown() async throws {
        StubURLProtocol.reset()
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeClient(
        tokenStore: TokenStore = MockTokenStore(),
        refreshService: TokenRefreshService = MockTokenRefreshService(),
        maxRetryCount: Int = 1
    ) -> NetworkClient {
        NetworkClient(
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

    /// 인증이 필요한 경로엔 저장된 access token이 Bearer 헤더로 주입된다.
    func test_request_authRequiredPath_injectsBearerToken() async throws {
        let store = MockTokenStore(accessToken: "abc-access", refreshToken: "r")
        let client = makeClient(tokenStore: store)
        StubURLProtocol.handler = { req in
            XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), "Bearer abc-access")
            return (Self.response(req.url, 200), Data("{}".utf8))
        }

        _ = try await client.request(request(path: "/photos"))
    }

    /// 공개 경로(/login)엔 토큰을 주입하지 않는다.
    func test_request_publicPath_doesNotInjectToken() async throws {
        let store = MockTokenStore(accessToken: "abc-access", refreshToken: "r")
        let client = makeClient(tokenStore: store)
        StubURLProtocol.handler = { req in
            XCTAssertNil(req.value(forHTTPHeaderField: "Authorization"))
            return (Self.response(req.url, 200), Data("{}".utf8))
        }

        _ = try await client.request(request(path: "/login", method: "POST"))
    }

    // MARK: - 성공 / 에러

    /// 2xx 응답이면 데이터와 응답을 그대로 반환한다.
    func test_request_success_returnsDataAndResponse() async throws {
        let client = makeClient()
        let payload = Data(#"{"value":42}"#.utf8)
        StubURLProtocol.handler = { req in (Self.response(req.url, 200), payload) }

        let (data, response) = try await client.request(request(path: "/photos"))

        XCTAssertEqual(data, payload)
        XCTAssertEqual(response.statusCode, 200)
    }

    /// 2xx도 401도 아닌 응답은 NetworkError.httpError로 던진다.
    func test_request_serverError_throwsHttpError() async throws {
        let client = makeClient()
        StubURLProtocol.handler = { req in (Self.response(req.url, 500), Data("boom".utf8)) }

        do {
            _ = try await client.request(request(path: "/photos"))
            XCTFail("expected throw")
        } catch let NetworkError.httpError(code, _) {
            XCTAssertEqual(code, 500)
        }
    }

    // MARK: - 401 → 토큰 갱신

    /// 401 → 토큰 갱신 성공 → 새 토큰으로 재시도 → 성공. 갱신은 1회만.
    func test_request_401ThenRefreshSucceeds_retriesWithNewTokenAndSucceeds() async throws {
        let store = MockTokenStore(accessToken: "old", refreshToken: "r")
        let refresh = SpyRefreshService(success: TokenPair(accessToken: "new", refreshToken: "r2"))
        let client = makeClient(tokenStore: store, refreshService: refresh)
        StubURLProtocol.handler = { req in
            let authorized = req.value(forHTTPHeaderField: "Authorization") == "Bearer new"
            return (Self.response(req.url, authorized ? 200 : 401), Data("{}".utf8))
        }

        let (_, response) = try await client.request(request(path: "/photos"))

        XCTAssertEqual(response.statusCode, 200)
        let refreshCount = await refresh.count()
        XCTAssertEqual(refreshCount, 1)
        let savedAccess = await store.getAccessToken()
        XCTAssertEqual(savedAccess, "new", "갱신된 토큰이 저장소에 반영돼야 한다")
    }

    /// 401 → 갱신 실패 → unauthorized를 던지고 onRefreshFailed 콜백이 호출된다.
    func test_request_401AndRefreshFails_throwsUnauthorizedAndFiresCallback() async throws {
        let refresh = SpyRefreshService(success: nil) // 실패
        let client = makeClient(refreshService: refresh)
        let callback = CallbackFlag()
        await client.setOnRefreshFailed { callback.fire() }
        StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) }

        do {
            _ = try await client.request(request(path: "/photos"))
            XCTFail("expected throw")
        } catch {
            guard case NetworkError.unauthorized = error else {
                return XCTFail("expected .unauthorized, got \(error)")
            }
        }
        XCTAssertTrue(callback.value, "갱신 실패 시 onRefreshFailed가 호출돼야 한다")
    }

    /// 갱신은 성공해도 서버가 계속 401이면, 재시도 한도 초과 후 unauthorized + 콜백.
    func test_request_persistent401_exhaustsRetryThenUnauthorized() async throws {
        let refresh = SpyRefreshService(success: TokenPair(accessToken: "new", refreshToken: "r2"))
        let client = makeClient(refreshService: refresh, maxRetryCount: 1)
        let callback = CallbackFlag()
        await client.setOnRefreshFailed { callback.fire() }
        StubURLProtocol.handler = { req in (Self.response(req.url, 401), Data("{}".utf8)) } // 항상 401

        do {
            _ = try await client.request(request(path: "/photos"))
            XCTFail("expected throw")
        } catch {
            guard case NetworkError.unauthorized = error else {
                return XCTFail("expected .unauthorized, got \(error)")
            }
        }
        let refreshCount = await refresh.count()
        XCTAssertEqual(refreshCount, 1, "재시도 한도 안에서 갱신은 1회만 시도된다")
        XCTAssertTrue(callback.value)
    }

    // MARK: - ⭐ Thundering-herd 방지

    /// 동시에 20개 요청이 모두 401을 받아도 토큰 갱신은 정확히 1회만 수행된다.
    func test_concurrentRequests_on401_refreshesTokenExactlyOnce() async throws {
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

        XCTAssertEqual(successCount, requestCount, "모든 동시 요청이 결국 성공해야 한다")
        let refreshCount = await refresh.count()
        XCTAssertEqual(refreshCount, 1, "동시 401에도 토큰 갱신은 단 1회여야 한다 (thundering-herd 방지)")
    }

    // MARK: - logout

    /// logout은 저장된 토큰을 삭제하고 로그인 상태를 false로 만든다.
    func test_logout_clearsStoredTokens() async throws {
        let store = MockTokenStore(accessToken: "a", refreshToken: "r")
        let client = makeClient(tokenStore: store)
        let before = await client.isLoggedIn()
        XCTAssertTrue(before)

        try await client.logout()

        let after = await client.isLoggedIn()
        XCTAssertFalse(after)
        let access = await store.getAccessToken()
        XCTAssertNil(access)
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

/// @Sendable 콜백에서 안전하게 호출 여부를 기록하는 플래그.
final class CallbackFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var fired = false
    func fire() { lock.withLock { fired = true } }
    var value: Bool { lock.withLock { fired } }
}
