//
//  TagRepositoryTests.swift
//  TagDomainTests
//
//  Created by Doyeon Kim on 11/3/26.
//

import Foundation
import Synchronization
import Testing
import NetworkAdapter
import NetworkAdapterTesting
import TagDomainInterface
@testable import TagDomain

extension StubURLProtocolSuites {

    /// TagRepository의 요청 조립 · 응답 매핑 검증.
    ///
    /// 서버 대신 StubURLProtocol이 응답하므로 경로 · 메서드 · 바디와 DTO → 도메인 변환만 본다.
    @Suite("TagRepository")
    struct TagRepositoryTests {

        // MARK: - Helpers

        private func makeSUT(decoder: JSONDecoder = JSONDecoder()) -> TagRepository {
            StubURLProtocol.reset()
            let client = NetworkClient(
                session: StubURLProtocol.session(),
                tokenStore: MockTokenStore(),
                refreshService: MockTokenRefreshService()
            )
            let adapter = NetworkAdapter(networkClient: client, baseURL: URL(string: "https://api.test")!)
            return TagRepository(adapter: adapter, decoder: decoder)
        }

        private static func ok(_ request: URLRequest, body: String) -> (HTTPURLResponse, Data) {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }

        private static func tagJSON(photoTagId: Int, tagId: Int, tagName: String, photoId: Int) -> String {
            #"{"photoTagId":\#(photoTagId),"tagId":\#(tagId),"tagName":"\#(tagName)","photoId":\#(photoId)}"#
        }

        private func jsonBody(of request: URLRequest) throws -> NSDictionary {
            try #require(JSONSerialization.jsonObject(with: request.bodyData) as? NSDictionary)
        }

        // MARK: - Tests

        @Test("getTags — 사진 하위 경로로 GET하고 응답 배열을 도메인 모델로 매핑한다")
        func getTagsMapsResponse() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in
                Self.ok(request, body: "[\(Self.tagJSON(photoTagId: 10, tagId: 1, tagName: "바다", photoId: 7)),\(Self.tagJSON(photoTagId: 11, tagId: 2, tagName: "노을", photoId: 7))]")
            }

            let tags = try await sut.getTags(photoId: 7)

            let request = try #require(StubURLProtocol.recordedRequests.first)
            #expect(request.url?.path == "/photos/7/tags")
            #expect(request.httpMethod == "GET")
            #expect(tags.map(\.id) == [10, 11])
            #expect(tags.map(\.tagName) == ["바다", "노을"])
            #expect(tags.allSatisfy { $0.photoId == 7 })
        }

        @Test("addTag — photoId와 tagName을 POST 바디에 싣고 생성된 태그를 반환한다")
        func addTagSendsBodyAndMapsResponse() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in
                Self.ok(request, body: Self.tagJSON(photoTagId: 20, tagId: 3, tagName: "바다", photoId: 7))
            }

            let tag = try await sut.addTag(photoId: 7, tagName: "바다")

            let request = try #require(StubURLProtocol.recordedRequests.first)
            #expect(request.url?.path == "/tags")
            #expect(request.httpMethod == "POST")
            let body = try jsonBody(of: request)
            #expect(body["photoId"] as? Int == 7)
            #expect(body["tagName"] as? String == "바다")
            #expect(tag.photoTagId == 20)
            #expect(tag.tagName == "바다")
        }

        @Test("updateTag — 식별자는 path로, 바디에는 tagName만 싣는다")
        func updateTagPutsOnlyTagName() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in
                Self.ok(request, body: Self.tagJSON(photoTagId: 20, tagId: 3, tagName: "노을", photoId: 7))
            }

            let tag = try await sut.updateTag(photoTagId: 20, tagName: "노을")

            let request = try #require(StubURLProtocol.recordedRequests.first)
            #expect(request.url?.path == "/tags/20")
            #expect(request.httpMethod == "PUT")
            let body = try jsonBody(of: request)
            #expect(body.count == 1)
            #expect(body["tagName"] as? String == "노을")
            #expect(tag.tagName == "노을")
        }

        @Test("deleteTag — 바디 없이 DELETE하고 응답 본문은 무시한다")
        func deleteTagSendsPlainDelete() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in Self.ok(request, body: "") }

            try await sut.deleteTag(photoTagId: 20)

            let request = try #require(StubURLProtocol.recordedRequests.first)
            #expect(request.url?.path == "/tags/20")
            #expect(request.httpMethod == "DELETE")
            #expect(request.bodyData.isEmpty)
        }

        @Test("응답이 DTO 형태가 아니면 디코딩 에러를 그대로 던진다")
        func invalidResponseThrowsDecodingError() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in Self.ok(request, body: #"{"unexpected":true}"#) }

            await #expect(throws: DecodingError.self) {
                _ = try await sut.getTags(photoId: 7)
            }
        }

        /// `decode`를 가로채 호출 스레드를 기록한다. Repository가 `@concurrent`로 빠져나갔는지 보는 용도.
        private final class RecordingDecoder: JSONDecoder, @unchecked Sendable {
            let decodedOnMainThread = Mutex<Bool?>(nil)

            override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
                decodedOnMainThread.withLock { $0 = Thread.isMainThread }
                return try super.decode(type, from: data)
            }
        }

        @Test("메인 액터에서 호출해도 디코딩은 메인 스레드 밖에서 실행된다")
        @MainActor
        func decodesOutsideMainActor() async throws {
            MainActor.preconditionIsolated()
            let decoder = RecordingDecoder()
            let sut = makeSUT(decoder: decoder)
            StubURLProtocol.handler = { request in Self.ok(request, body: "[]") }

            _ = try await sut.getTags(photoId: 7)

            #expect(decoder.decodedOnMainThread.withLock { $0 } == false)
        }
    }
}
