//
//  SearchRepositoryTests.swift
//  PhotoDomainTests
//
//  Created by Doyeon Kim on 11/9/26.
//

import Foundation
import Synchronization
import Testing
import NetworkAdapter
import NetworkAdapterTesting
import PhotoDomainInterface
@testable import PhotoDomain

/// `decode`를 가로채 호출 스레드를 기록한다. MainActor 테스트 안에 두면 격리가 따라붙으므로 파일 범위에 둔다.
private final class SearchRecordingDecoder: JSONDecoder, @unchecked Sendable {
    let decodedOnMainThread = Mutex<Bool?>(nil)

    override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        decodedOnMainThread.withLock { $0 = Thread.isMainThread }
        return try super.decode(type, from: data)
    }
}

extension StubURLProtocolSuites {

    @Suite("SearchRepository")
    struct SearchRepositoryTests {

        private func makeSUT(decoder: JSONDecoder = JSONDecoder()) -> SearchRepository {
            StubURLProtocol.reset()
            let client = NetworkClient(
                session: StubURLProtocol.session(),
                tokenStore: MockTokenStore(),
                refreshService: MockTokenRefreshService()
            )
            let adapter = NetworkAdapter(networkClient: client, baseURL: URL(string: "https://api.test")!)
            return SearchRepository(adapter: adapter, decoder: decoder)
        }

        private static func ok(_ request: URLRequest, body: String) -> (HTTPURLResponse, Data) {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }

        @Test("search — 질의를 POST 바디에 싣고 searchResults를 도메인 모델로 매핑한다")
        func searchSendsQueryAndMapsResults() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in
                Self.ok(request, body: #"{"query":"바다","searchResults":[{"imageUrl":"https://cdn.test/1.jpg","photoId":1},{"imageUrl":"https://cdn.test/2.jpg","photoId":2}]}"#)
            }

            let results = try await sut.search(query: "바다")

            let request = try #require(StubURLProtocol.recordedRequests.first)
            #expect(request.url?.path == "/search")
            #expect(request.httpMethod == "POST")
            let body = try #require(JSONSerialization.jsonObject(with: request.bodyData) as? NSDictionary)
            #expect(body["query"] as? String == "바다")
            #expect(results == [
                SearchResult(imageUrl: URL(string: "https://cdn.test/1.jpg")!, photoId: 1),
                SearchResult(imageUrl: URL(string: "https://cdn.test/2.jpg")!, photoId: 2),
            ])
        }

        @Test("결과가 없으면 빈 배열을 반환한다")
        func emptyResultsReturnEmptyArray() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in Self.ok(request, body: #"{"query":"없음","searchResults":[]}"#) }

            let results = try await sut.search(query: "없음")

            #expect(results.isEmpty)
        }

        @Test("searchResults 키가 없으면 디코딩 에러를 그대로 던진다")
        func missingResultsThrowsDecodingError() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in Self.ok(request, body: #"{"query":"바다"}"#) }

            await #expect(throws: DecodingError.self) {
                _ = try await sut.search(query: "바다")
            }
        }

        @Test("메인 액터에서 호출해도 디코딩은 메인 스레드 밖에서 실행된다")
        @MainActor
        func decodesOutsideMainActor() async throws {
            MainActor.preconditionIsolated()
            let decoder = SearchRecordingDecoder()
            let sut = makeSUT(decoder: decoder)
            StubURLProtocol.handler = { request in Self.ok(request, body: #"{"query":"바다","searchResults":[]}"#) }

            _ = try await sut.search(query: "바다")

            #expect(decoder.decodedOnMainThread.withLock { $0 } == false)
        }
    }
}
