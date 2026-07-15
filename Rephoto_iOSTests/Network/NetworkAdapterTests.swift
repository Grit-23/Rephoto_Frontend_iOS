//
//  NetworkAdapterTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// NetworkAdapter의 URLRequest 조립 검증
///
/// 서버 없이 buildURLRequest 출력(method/URL/헤더/바디)을 직접 검증한다.
/// JSON 바디는 직렬화 키 순서가 비결정적이므로 바이트 비교 대신 파싱 후 비교한다.
@Suite("NetworkAdapter")
@MainActor
struct NetworkAdapterTests {

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
        let request = try makeSUT().buildURLRequest(PhotosAPITarget.getAllPhotos)

        #expect(request.httpMethod == "GET")
        #expect(request.url == URL(string: "https://api.test/photos"))
        #expect(request.httpBody == nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test(".plain DELETE는 경로 파라미터를 URL에 보간한다")
    func plainDeleteInterpolatesPathParameter() throws {
        let request = try makeSUT().buildURLRequest(PhotosAPITarget.deletePhoto(photoId: 123))

        #expect(request.httpMethod == "DELETE")
        #expect(request.url == URL(string: "https://api.test/photos/123"))
        #expect(request.httpBody == nil)
    }

    // MARK: - .jsonEncodable

    @Test(".jsonEncodable은 DTO 필드를 JSON 바디로 인코딩한다")
    func jsonEncodableAddTagEncodesDTOFields() throws {
        let target = TagAPITarget.addTag(request: AddTagRequestDTO(photoId: 7, tagName: "바다"))
        let request = try makeSUT().buildURLRequest(target)

        #expect(request.httpMethod == "POST")
        #expect(request.url == URL(string: "https://api.test/tags"))
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(try jsonBody(of: request) == ["photoId": 7, "tagName": "바다"])
    }

    @Test("로그인 요청은 자격증명을 JSON 바디로 인코딩한다")
    func jsonEncodableLoginEncodesCredentials() throws {
        let target = UserAPITarget.login(loginId: "dodle", password: "secret!")
        let request = try makeSUT().buildURLRequest(target)

        #expect(request.httpMethod == "POST")
        #expect(request.url == URL(string: "https://api.test/login"))
        #expect(try jsonBody(of: request) == ["loginId": "dodle", "password": "secret!"])
    }

    /// RefreshTokenRequestDTO는 CodingKeys로 서버가 기대하는 "Authorization" 필드명에 매핑된다.
    @Test("리프레시 토큰 요청은 서버가 기대하는 Authorization 바디 키로 인코딩된다")
    func jsonEncodableRefreshTokenUsesAuthorizationBodyKey() throws {
        let target = UserAPITarget.refreshToken(refreshToken: "refresh-token-value")
        let request = try makeSUT().buildURLRequest(target)

        #expect(request.url == URL(string: "https://api.test/auth/refresh"))
        #expect(try jsonBody(of: request) == ["Authorization": "refresh-token-value"])
    }

    @Test("검색 요청은 query를 JSON 바디로 인코딩한다")
    func jsonEncodableSearchEncodesQuery() throws {
        let request = try makeSUT().buildURLRequest(SearchAPITarget.search(query: "제주도 바다"))

        #expect(request.httpMethod == "POST")
        #expect(request.url == URL(string: "https://api.test/search"))
        #expect(try jsonBody(of: request) == ["query": "제주도 바다"])
    }

    // MARK: - .multipart

    /// boundary는 요청마다 랜덤 생성되므로 값 비교 대신 헤더에서 추출해 구조를 검증한다.
    /// 파일 데이터는 유효한 UTF-8이 아닌 바이너리를 사용해, 조립 과정에서 바이트가 훼손되지 않음을 함께 검증한다.
    @Test(".multipart는 규격에 맞는 바디를 조립하고 바이너리를 그대로 보존한다")
    func multipartS3UploadBuildsWellFormedBody() throws {
        // JPEG 헤더 유사 바이트 — 0xFF/0x00 포함, UTF-8로 디코딩 불가
        let fileData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01])
        let request = try makeSUT().buildURLRequest(PhotosAPITarget.s3Upload(file: fileData))

        #expect(request.httpMethod == "POST")
        #expect(request.url == URL(string: "https://api.test/photos/s3"))

        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))
        let boundary = String(contentType.dropFirst("multipart/form-data; boundary=".count))
        #expect(!boundary.isEmpty)

        let body = try #require(request.httpBody)
        let partHeader = Data(
            "--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".utf8
        )
        let terminator = Data("\r\n--\(boundary)--\r\n".utf8)

        // 파트 헤더 + 원본 바이트 + 종결 boundary가 바이트 단위로 정확히 일치해야 한다
        #expect(body == partHeader + fileData + terminator)
    }

    /// s3Upload는 타겟 헤더가 nil이라 어댑터가 설정한 multipart Content-Type만 존재해야 한다.
    @Test(".multipart의 Content-Type은 JSON 기본 헤더로 덮어쓰이지 않는다")
    func multipartS3UploadDoesNotOverrideContentTypeWithJSON() throws {
        let request = try makeSUT().buildURLRequest(PhotosAPITarget.s3Upload(file: Data()))

        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
        #expect(!contentType.contains("application/json"))
    }
}
