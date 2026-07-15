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

        deinit {
            for url in tempFiles { try? FileManager.default.removeItem(at: url) }
        }

        // MARK: - Helpers

        private func makeSUT() -> PhotoRepository {
            StubURLProtocol.reset()
            let session = StubURLProtocol.session()
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
            try Data("fake image data \(id)".utf8).write(to: url)
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

            let lock = NSLock()
            nonisolated(unsafe) var failureEmitted = false

            StubURLProtocol.handler = { request in
                let path = request.url?.path ?? ""
                if path.hasSuffix("/photos/batch") {
                    // 호출되면 안 되는 경로 — 아래 count 검증으로 잡는다.
                    throw URLError(.unknown)
                }
                // 첫 S3 요청만 500을 반환해 한 건 실패를 보장한다.
                let shouldFail: Bool = lock.withLock {
                    if !failureEmitted {
                        failureEmitted = true
                        return true
                    }
                    return false
                }
                if shouldFail {
                    return (Self.errorResponse(for: request, code: 500), Data("server error".utf8))
                }
                let body = #"{"imageUrl":"https://s3.test/uploaded.jpg"}"#
                return (Self.okResponse(for: request), Data(body.utf8))
            }

            await #expect(throws: (any Error).self) {
                try await sut.uploadPhotos(items: items)
            }

            let batchCalls = StubURLProtocol.recordedRequests.filter {
                $0.url?.path.hasSuffix("/photos/batch") == true
            }
            #expect(batchCalls.isEmpty, "S3 실패 시 batch save는 실행되면 안 된다")
        }
    }
}
