//
//  TestHelpers.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 6/6/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

// MARK: - RequestTask 검증 헬퍼

/// APITarget 계약 테스트용 RequestTask 구조 접근자.
///
/// RequestTask는 연관값에 `any Encodable`을 담아 Equatable을 만족시킬 수 없으므로,
/// 케이스 판별과 연관값 추출을 옵셔널 반환으로 감싸 `#require`/`#expect`와 조합해 쓴다.
extension RequestTask {

    /// 바디가 없는 요청인지 여부
    var isPlain: Bool {
        if case .plain = self { return true }
        return false
    }

    /// `.jsonEncodable`의 바디를 구체 DTO 타입으로 꺼낸다. 케이스나 타입이 다르면 nil.
    func jsonBody<T: Encodable>(as type: T.Type) -> T? {
        guard case .jsonEncodable(let body) = self else { return nil }
        return body as? T
    }

    /// `.multipart`의 파트 목록을 꺼낸다. 다른 케이스면 nil.
    var multipartItems: [MultipartFormItem]? {
        guard case .multipart(let items) = self else { return nil }
        return items
    }
}

// MARK: - 직렬화 컨테이너

/// StubURLProtocol의 전역 상태(handler/recordedRequests)를 공유하는 스위트들의 컨테이너.
///
/// Swift Testing은 스위트 간에도 병렬 실행하므로, 스텁 상태를 공유하는 스위트는
/// 이 컨테이너의 extension으로 선언해 전체를 직렬 실행시킨다 (.serialized는 자식에 재귀 적용).
@Suite(.serialized)
enum StubURLProtocolSuites {}

// MARK: - StubURLProtocol

/// URLSession의 모든 요청을 가로채 핸들러로 응답을 반환하는 stub.
///
/// 사용법:
///   StubURLProtocol.handler = { request in ... }
///   let session = StubURLProtocol.session()
final class StubURLProtocol: URLProtocol, @unchecked Sendable {

    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _handler: Handler?
    nonisolated(unsafe) private static var _recordedRequests: [URLRequest] = []

    static var handler: Handler? {
        get { lock.withLock { _handler } }
        set { lock.withLock { _handler = newValue } }
    }

    static var recordedRequests: [URLRequest] {
        lock.withLock { _recordedRequests }
    }

    static func reset() {
        lock.withLock {
            _handler = nil
            _recordedRequests = []
        }
    }

    static func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.withLock { Self._recordedRequests.append(request) }

        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - MockTokenStore

final actor MockTokenStore: TokenStore {
    private var access: String?
    private var refresh: String?

    init(accessToken: String? = "test-access", refreshToken: String? = "test-refresh") {
        self.access = accessToken
        self.refresh = refreshToken
    }

    func getAccessToken() async -> String? { access }
    func getRefreshToken() async -> String? { refresh }

    func save(accessToken: String, refreshToken: String) async throws {
        access = accessToken
        refresh = refreshToken
    }

    func clear() async throws {
        access = nil
        refresh = nil
    }
}

// MARK: - MockTokenRefreshService

struct MockTokenRefreshService: TokenRefreshService {
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        throw URLError(.userAuthenticationRequired)
    }
}
