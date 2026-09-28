//
//  PhotoRepositoryTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 6/6/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

extension StubURLProtocolSuites {

    @Suite("PhotoRepository")
    @MainActor
    final class PhotoRepositoryTests {

        private var tempFiles: [URL] = []
        private var sessions: [URLSession] = []

        deinit {
            for url in tempFiles { try? FileManager.default.removeItem(at: url) }
            // 실패로 취소된 동시 요청이 다음 테스트의 핸들러로 흘러들지 않게 세션째 끊는다
            for session in sessions { session.invalidateAndCancel() }
        }

        // MARK: - Helpers

        private func makeSUT() -> PhotoRepository {
            StubURLProtocol.reset()
            let session = StubURLProtocol.session()
            sessions.append(session)
            let baseURL = URL(string: "https://api.test")!
            let networkClient = NetworkClient(
                session: session,
                tokenStore: MockTokenStore(),
                refreshService: MockTokenRefreshService()
            )
            let adapter = NetworkAdapter(networkClient: networkClient, baseURL: baseURL)
            return PhotoRepository(adapter: adapter)
        }

        private func makeUploadItem(id: Int) throws -> PhotoUploadItem {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("test_upload_\(id)_\(UUID().uuidString).jpg")
            // 파일명(UUID 포함)을 내용에 넣어 테스트·반복 간에 바디가 겹치지 않게 한다
            try Data("fake image data \(id) \(url.lastPathComponent)".utf8).write(to: url)
            tempFiles.append(url)
            return PhotoUploadItem(
                latitude: 37.5,
                longitude: 126.9,
                imageUrl: url,
                createdAt: "2026-06-06T12:00:00",
                fileName: url.lastPathComponent
            )
        }

        // StubURLProtocol.handler(nonisolated @Sendable 클로저)에서 호출되므로 MainActor 격리 해제
        private nonisolated static func okResponse(for request: URLRequest) -> HTTPURLResponse {
            HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        }

        private nonisolated static func errorResponse(for request: URLRequest, code: Int) -> HTTPURLResponse {
            HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
        }

        // MARK: - Tests

        @Test("빈 배열은 어떤 네트워크 요청도 발생시키지 않고 즉시 반환한다")
        func emptyItemsMakeNoRequests() async throws {
            let sut = makeSUT()
            // 요청이 발생하면 안 되므로, 발생 시 에러를 던지고 아래 count 검증으로 잡는다.
            StubURLProtocol.handler = { _ in throw URLError(.unknown) }

            try await sut.uploadPhotos(items: [])

            #expect(StubURLProtocol.recordedRequests.isEmpty)
        }

        @Test("모든 item이 성공하면 각 item당 S3 1회 + batch save 1회 호출된다")
        func uploadsEachItemThenCallsBatchSave() async throws {
            let sut = makeSUT()
            let items = try (0..<3).map { try makeUploadItem(id: $0) }

            StubURLProtocol.handler = { request in
                let path = request.url?.path ?? ""
                if path.hasSuffix("/photos/s3") {
                    let body = #"{"imageUrl":"https://s3.test/uploaded.jpg"}"#
                    return (Self.okResponse(for: request), Data(body.utf8))
                } else if path.hasSuffix("/photos/batch") {
                    return (Self.okResponse(for: request), Data("{}".utf8))
                } else {
                    throw URLError(.badURL) // 예상 밖 경로 → 요청 실패로 테스트가 throw
                }
            }

            try await sut.uploadPhotos(items: items)

            let recorded = StubURLProtocol.recordedRequests
            let s3Calls = recorded.filter { $0.url?.path.hasSuffix("/photos/s3") == true }
            let batchCalls = recorded.filter { $0.url?.path.hasSuffix("/photos/batch") == true }
            #expect(s3Calls.count == 3, "S3 업로드는 item당 1회씩 호출돼야 한다")
            #expect(batchCalls.count == 1, "batch save는 정확히 1회 호출돼야 한다")
        }

        @Test("S3 업로드 중 한 건이라도 실패하면 throw하고 batch save는 호출되지 않는다")
        func anyS3FailureThrowsAndSkipsBatchSave() async throws {
            let sut = makeSUT()
            let items = try (0..<3).map { try makeUploadItem(id: $0) }
            // 실패 대상은 도착 순서가 아니라 내용으로 고른다.
            // "첫 요청만 500" 방식은 이전 테스트에서 취소된 요청이 늦게 도착해 그 1회를 가져가면
            // 이번 업로드가 전부 성공해 batch까지 호출되는 flaky가 있었다.
            let failingMarker = try Data(contentsOf: items[1].imageUrl)

            StubURLProtocol.handler = { request in
                let path = request.url?.path ?? ""
                if path.hasSuffix("/photos/batch") {
                    // 호출되면 안 되는 경로 — 아래 count 검증으로 잡는다.
                    throw URLError(.unknown)
                }
                // 특정 item의 S3 요청만 500을 반환해 한 건 실패를 보장한다.
                let shouldFail = request.bodyData.range(of: failingMarker) != nil
                if shouldFail {
                    return (Self.errorResponse(for: request, code: 500), Data("server error".utf8))
                }
                let body = #"{"imageUrl":"https://s3.test/uploaded.jpg"}"#
                return (Self.okResponse(for: request), Data(body.utf8))
            }

            // 어떤 에러든 통과시키면 다른 원인(디코딩·파일 읽기 실패)도 성공으로 보인다.
            // S3 500이 그대로 호출부까지 전파되는지 에러 값으로 고정한다.
            await #expect(throws: NetworkError.httpError(statusCode: 500, data: Data("server error".utf8))) {
                try await sut.uploadPhotos(items: items)
            }

            let batchCalls = StubURLProtocol.recordedRequests.filter {
                $0.url?.path.hasSuffix("/photos/batch") == true
            }
            #expect(batchCalls.isEmpty, "S3 실패 시 batch save는 실행되면 안 된다")
        }
    }
}
