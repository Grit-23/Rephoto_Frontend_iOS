//
//  StubURLProtocol.swift
//  NetworkAdapterTesting
//
//  Created by Doyeon Kim on 6/6/26.
//

import Foundation

/// URLSession의 모든 요청을 가로채 핸들러로 응답을 반환하는 stub.
///
/// 상태(`handler` · `recordedRequests`)가 전역이므로, 이를 공유하는 스위트는
/// `.serialized` 컨테이너 스위트의 extension으로 선언해 직렬 실행시킨다.
///
/// 사용법:
///   StubURLProtocol.handler = { request in ... }
///   let session = StubURLProtocol.session()
public final class StubURLProtocol: URLProtocol, @unchecked Sendable {

    public typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _handler: Handler?
    nonisolated(unsafe) private static var _recordedRequests: [URLRequest] = []

    public static var handler: Handler? {
        get { lock.withLock { _handler } }
        set { lock.withLock { _handler = newValue } }
    }

    public static var recordedRequests: [URLRequest] {
        lock.withLock { _recordedRequests }
    }

    public static func reset() {
        lock.withLock {
            _handler = nil
            _recordedRequests = []
        }
    }

    public static func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: URLProtocol

    public override class func canInit(with request: URLRequest) -> Bool { true }
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    public override func startLoading() {
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

    public override func stopLoading() {}
}

// MARK: - URLRequest 바디 헬퍼

extension URLRequest {

    /// StubURLProtocol에 도달한 요청의 바디.
    ///
    /// URLSession은 `httpBody`를 `httpBodyStream`으로 바꿔 넘길 수 있어 둘 다 읽는다.
    public var bodyData: Data {
        if let body = httpBody { return body }
        guard let stream = httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
