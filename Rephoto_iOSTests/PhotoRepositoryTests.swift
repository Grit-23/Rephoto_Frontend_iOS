//
//  PhotoRepositoryTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 6/6/26.
//

import XCTest
@testable import Rephoto_iOS

final class PhotoRepositoryTests: XCTestCase {

    private var tempFiles: [URL] = []

    override func tearDown() async throws {
        for url in tempFiles { try? FileManager.default.removeItem(at: url) }
        tempFiles = []
        StubURLProtocol.reset()
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeSUT() -> PhotoRepository {
        let session = StubURLProtocol.session()
        let baseURL = URL(string: "https://api.test")!
        let networkClient = NetworkClient(
            session: session,
            tokenStore: MockTokenStore(),
            refreshService: MockTokenRefreshService()
        )
        let adapter = MoyaNetworkAdapter(networkClient: networkClient, baseURL: baseURL)
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

    private static func okResponse(for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private static func errorResponse(for request: URLRequest, code: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
    }

    // MARK: - Tests

    /// 빈 배열은 어떤 네트워크 요청도 발생시키지 않고 즉시 반환한다.
    func test_uploadPhotos_emptyItems_makesNoRequests() async throws {
        let sut = makeSUT()
        StubURLProtocol.handler = { _ in
            XCTFail("Empty items must not trigger any request")
            throw URLError(.unknown)
        }

        try await sut.uploadPhotos(items: [])

        XCTAssertEqual(StubURLProtocol.recordedRequests.count, 0)
    }

    /// 모든 item이 성공하면 각 item당 S3 1회 + batch save 1회 호출된다.
    func test_uploadPhotos_allSuccess_uploadsEachItemThenCallsBatchSave() async throws {
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
                XCTFail("Unexpected path: \(path)")
                throw URLError(.badURL)
            }
        }

        try await sut.uploadPhotos(items: items)

        let recorded = StubURLProtocol.recordedRequests
        let s3Calls = recorded.filter { $0.url?.path.hasSuffix("/photos/s3") == true }
        let batchCalls = recorded.filter { $0.url?.path.hasSuffix("/photos/batch") == true }
        XCTAssertEqual(s3Calls.count, 3, "S3 upload should be called once per item")
        XCTAssertEqual(batchCalls.count, 1, "Batch save should be called exactly once")
    }

    /// S3 업로드 중 한 건이라도 실패하면 throw하고 batch save는 호출되지 않는다.
    func test_uploadPhotos_anyS3Failure_throwsAndSkipsBatchSave() async throws {
        let sut = makeSUT()
        let items = try (0..<3).map { try makeUploadItem(id: $0) }

        let lock = NSLock()
        nonisolated(unsafe) var failureEmitted = false

        StubURLProtocol.handler = { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("/photos/batch") {
                XCTFail("Batch save must not run when any S3 upload fails")
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

        do {
            try await sut.uploadPhotos(items: items)
            XCTFail("Expected uploadPhotos to throw")
        } catch {
            // 성공: 에러가 정상 전파됨
        }

        let batchCalls = StubURLProtocol.recordedRequests.filter {
            $0.url?.path.hasSuffix("/photos/batch") == true
        }
        XCTAssertEqual(batchCalls.count, 0)
    }
}
