//
//  DescriptionRepositoryTests.swift
//  PhotoDomainTests
//
//  Created by Doyeon Kim on 11/4/26.
//

import Foundation
import Testing
import NetworkAdapter
import NetworkAdapterTesting
@testable import PhotoDomain

extension StubURLProtocolSuites {

    @Suite("DescriptionRepository")
    struct DescriptionRepositoryTests {

        private func makeSUT() -> DescriptionRepository {
            StubURLProtocol.reset()
            let client = NetworkClient(
                session: StubURLProtocol.session(),
                tokenStore: MockTokenStore(),
                refreshService: MockTokenRefreshService()
            )
            let adapter = NetworkAdapter(networkClient: client, baseURL: URL(string: "https://api.test")!)
            return DescriptionRepository(adapter: adapter)
        }

        private static func ok(_ request: URLRequest, body: String) -> (HTTPURLResponse, Data) {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }

        @Test("getDescription — 사진 하위 경로로 GET하고 description 필드만 꺼낸다")
        func getDescriptionMapsResponse() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in Self.ok(request, body: #"{"description":"제주 바다"}"#) }

            let description = try await sut.getDescription(photoId: 7)

            let request = try #require(StubURLProtocol.recordedRequests.first)
            #expect(request.url?.path == "/photos/7/description")
            #expect(request.httpMethod == "GET")
            #expect(description == "제주 바다")
        }

        @Test("응답에 description이 없으면 디코딩 에러를 그대로 던진다")
        func missingFieldThrowsDecodingError() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { request in Self.ok(request, body: "{}") }

            await #expect(throws: DecodingError.self) {
                _ = try await sut.getDescription(photoId: 7)
            }
        }
    }
}
