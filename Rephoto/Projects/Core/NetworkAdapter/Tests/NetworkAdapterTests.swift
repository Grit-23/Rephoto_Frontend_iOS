//
//  NetworkAdapterTests.swift
//  NetworkAdapterTests
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation
import Testing
import NetworkAdapterTesting
@testable import NetworkAdapter

/// NetworkAdapter의 URLRequest 조립 검증
///
/// 서버 없이 buildURLRequest 출력(method/URL/헤더/바디)을 직접 검증한다.
/// 실제 API 선언은 Domain 모듈에 있으므로 여기서는 필드를 직접 채우는 타겟으로 조립 규칙만 본다.
/// JSON 바디는 직렬화 키 순서가 비결정적이므로 바이트 비교 대신 파싱 후 비교한다.
@Suite("NetworkAdapter")
struct NetworkAdapterTests {

    /// 필드를 직접 지정하는 타겟. `headers`를 저장 프로퍼티로 둬 nil까지 표현한다.
    private struct StubTarget: APITargetType {
        var path: String
        var method: HTTPMethod = .get
        var task: RequestTask = .plain
        var headers: [String: String]? = ["Content-Type": "application/json"]
    }

    /// `headers`를 선언하지 않아 프로토콜 기본 구현(JSON 헤더)을 쓰는 타겟.
    private struct DefaultHeaderTarget: APITargetType {
        let path = "/photos"
        let method: HTTPMethod = .get
        let task: RequestTask = .plain
    }

    private struct AddTagBody: Encodable, Sendable {
        let photoId: Int
        let tagName: String
    }

    private let baseURL = URL(string: "https://api.test")!

    private func makeSUT() -> NetworkAdapter {
        let networkClient = NetworkClient(
            session: StubURLProtocol.session(),
            tokenStore: MockTokenStore(),
            refreshService: MockTokenRefreshService()
        )
        return NetworkAdapter(networkClient: networkClient, baseURL: baseURL)
    }

    private func jsonBody(of request: URLRequest) throws -> NSDictionary {
        let body = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? NSDictionary)
    }

    // MARK: - .plain

    @Test(".plain GET은 메서드/URL/기본 JSON 헤더를 구성한다")
    func plainGetBuildsMethodURLAndDefaultHeader() throws {
        let request = try makeSUT().buildURLRequest(DefaultHeaderTarget())

        #expect(request.httpMethod == "GET")
        #expect(request.url == URL(string: "https://api.test/photos"))
        #expect(request.httpBody == nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test(".plain DELETE는 경로 파라미터를 URL에 보간한다")
    func plainDeleteInterpolatesPathParameter() throws {
        let photoId = 123
        let target = StubTarget(path: "/photos/\(photoId)", method: .delete)

        let request = try makeSUT().buildURLRequest(target)

        #expect(request.httpMethod == "DELETE")
        #expect(request.url == URL(string: "https://api.test/photos/123"))
        #expect(request.httpBody == nil)
    }

    // MARK: - .jsonEncodable

    @Test(".jsonEncodable은 DTO 필드를 JSON 바디로 인코딩한다")
    func jsonEncodableEncodesDTOFields() throws {
        let target = StubTarget(
            path: "/tags",
            method: .post,
            task: .jsonEncodable(AddTagBody(photoId: 7, tagName: "바다"))
        )

        let request = try makeSUT().buildURLRequest(target)

        #expect(request.httpMethod == "POST")
        #expect(request.url == URL(string: "https://api.test/tags"))
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(try jsonBody(of: request) == ["photoId": 7, "tagName": "바다"])
    }

    @Test("타겟이 지정한 헤더는 기본 헤더 대신 그대로 실린다")
    func customHeadersReplaceDefault() throws {
        let target = StubTarget(path: "/photos", headers: ["X-Trace": "abc"])

        let request = try makeSUT().buildURLRequest(target)

        #expect(request.value(forHTTPHeaderField: "X-Trace") == "abc")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
    }

    // MARK: - .multipart

    /// boundary는 요청마다 랜덤 생성되므로 값 비교 대신 헤더에서 추출해 구조를 검증한다.
    /// 파일 데이터는 유효한 UTF-8이 아닌 바이너리를 사용해, 조립 과정에서 바이트가 훼손되지 않음을 함께 검증한다.
    @Test(".multipart는 규격에 맞는 바디를 조립하고 바이너리를 그대로 보존한다")
    func multipartBuildsWellFormedBody() throws {
        // JPEG 헤더 유사 바이트 — 0xFF/0x00 포함, UTF-8로 디코딩 불가
        let fileData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01])
        let target = StubTarget(
            path: "/photos/s3",
            method: .post,
            task: .multipart([
                MultipartFormItem(data: fileData, name: "file", fileName: "photo.jpg", mimeType: "image/jpeg")
            ]),
            headers: nil
        )

        let request = try makeSUT().buildURLRequest(target)

        #expect(request.httpMethod == "POST")
        #expect(request.url == URL(string: "https://api.test/photos/s3"))

        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))
        let boundary = String(contentType.dropFirst("multipart/form-data; boundary=".count))
        #expect(boundary.isEmpty == false)

        let body = try #require(request.httpBody)
        let partHeader = Data(
            "--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".utf8
        )
        let terminator = Data("\r\n--\(boundary)--\r\n".utf8)

        // 파트 헤더 + 원본 바이트 + 종결 boundary가 바이트 단위로 정확히 일치해야 한다
        #expect(body == partHeader + fileData + terminator)
    }

    /// 타겟이 JSON Content-Type을 선언해도 multipart가 덮어쓴다 — 헤더가 먼저, 바디 조립이 나중이다.
    @Test(".multipart의 Content-Type은 타겟의 JSON 헤더에 덮어쓰이지 않는다")
    func multipartContentTypeWinsOverTargetHeader() throws {
        let target = StubTarget(
            path: "/photos/s3",
            method: .post,
            task: .multipart([MultipartFormItem(data: Data(), name: "file")])
        )

        let request = try makeSUT().buildURLRequest(target)

        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
        #expect(contentType.hasPrefix("multipart/form-data"))
        #expect(contentType.contains("application/json") == false)
    }
}

extension StubURLProtocolSuites {

    @MainActor
    @Suite("NetworkAdapter — 요청 실행")
    struct NetworkAdapterRequestTests {

        private struct EncodingContextBody: Encodable, Sendable {
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(Thread.isMainThread)
            }
        }

        private struct EncodingContextTarget: APITargetType {
            let path = "/login"
            let method: HTTPMethod = .post
            let task = RequestTask.jsonEncodable(EncodingContextBody())
        }

        @Test("메인 액터에서 요청해도 JSON 인코딩은 메인 스레드 밖에서 실행된다")
        func encodesRequestOutsideMainActor() async throws {
            MainActor.preconditionIsolated()
            StubURLProtocol.reset()
            defer { StubURLProtocol.reset() }
            StubURLProtocol.handler = { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, request.bodyData)
            }
            let client = NetworkClient(
                session: StubURLProtocol.session(),
                tokenStore: MockTokenStore(),
                refreshService: MockTokenRefreshService()
            )
            let adapter = NetworkAdapter(networkClient: client, baseURL: URL(string: "https://api.test")!)

            let data = try await adapter.request(EncodingContextTarget())

            #expect(data == Data("false".utf8))
        }
    }
}
