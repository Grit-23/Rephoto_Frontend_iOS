//
//  TestHelpers.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 6/6/26.
//

import Foundation
@testable import Rephoto_iOS

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
