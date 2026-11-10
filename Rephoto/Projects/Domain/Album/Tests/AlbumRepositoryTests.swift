//
//  AlbumRepositoryTests.swift
//  AlbumDomainTests
//
//  Created by Doyeon Kim on 11/9/26.
//

import Foundation
import Synchronization
import Testing
import NetworkAdapter
import NetworkAdapterTesting
import AlbumDomainInterface
@testable import AlbumDomain

/// `decode`를 가로채 호출 스레드를 기록한다. MainActor 테스트 안에 두면 격리가 따라붙으므로 파일 범위에 둔다.
private final class RecordingDecoder: JSONDecoder, @unchecked Sendable {
    let decodedOnMainThread = Mutex<Bool?>(nil)

    override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        decodedOnMainThread.withLock { $0 = Thread.isMainThread }
        return try super.decode(type, from: data)
    }
}

extension StubURLProtocolSuites {

    @Suite("AlbumRepository")
    struct AlbumRepositoryTests {

        private func makeSUT(decoder: JSONDecoder = JSONDecoder()) -> AlbumRepository {
            StubURLProtocol.reset()
            let client = NetworkClient(
                session: StubURLProtocol.session(),
                tokenStore: MockTokenStore(),
                refreshService: MockTokenRefreshService()
            )
            let adapter = NetworkAdapter(networkClient: client, baseURL: URL(string: "https://api.test")!)
            return AlbumRepository(adapter: adapter, decoder: decoder)
        }

        private static func ok(_ request: URLRequest, body: String) -> (HTTPURLResponse, Data) {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }

        @Test("getAlbums — GET /albums 응답을 도메인 모델로 매핑한다")
        func getAlbumsMapsResponse() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in
                Self.ok(request, body: #"[{"tagId":1,"tagName":"커피","coverImageUrl":"https://cdn.test/c.jpg","photoCount":3},{"tagId":2,"tagName":"빈앨범","coverImageUrl":null,"photoCount":0}]"#)
            }

            let albums = try await sut.getAlbums()

            let request = try #require(StubURLProtocol.recordedRequests.first)
            #expect(request.url?.path == "/albums")
            #expect(request.httpMethod == "GET")
            #expect(albums == [
                Album(tagId: 1, tagName: "커피", coverImageUrl: URL(string: "https://cdn.test/c.jpg"), photoCount: 3),
                Album(tagId: 2, tagName: "빈앨범", coverImageUrl: nil, photoCount: 0),
            ])
        }

        @Test("응답이 DTO 형태가 아니면 디코딩 에러를 그대로 던진다")
        func invalidResponseThrowsDecodingError() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in Self.ok(request, body: #"{"unexpected":true}"#) }

            await #expect(throws: DecodingError.self) {
                _ = try await sut.getAlbums()
            }
        }

        @Test("메인 액터에서 호출해도 디코딩은 메인 스레드 밖에서 실행된다")
        @MainActor
        func decodesOutsideMainActor() async throws {
            MainActor.preconditionIsolated()
            let decoder = RecordingDecoder()
            let sut = makeSUT(decoder: decoder)
            StubURLProtocol.handler = { request in Self.ok(request, body: "[]") }

            _ = try await sut.getAlbums()

            #expect(decoder.decodedOnMainThread.withLock { $0 } == false)
        }
    }
}
