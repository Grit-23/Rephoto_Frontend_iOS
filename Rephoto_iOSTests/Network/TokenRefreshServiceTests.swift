//
//  TokenRefreshServiceTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 9/28/26.
//
//  실제 토큰 갱신 요청(TokenRefreshServiceImpl)의 계약 검증.
//  NetworkClientTests는 Spy 갱신 서비스를 주입하므로 이 구현이 보내는 요청은 거치지 않는다.
//  바디 키 "Authorization"이 틀어지면 갱신이 조용히 실패하고 전 화면이 강제 로그아웃되므로
//  인코딩 결과까지 검증한다.
//

import Foundation
import Testing
@testable import Rephoto_iOS

extension StubURLProtocolSuites {

    @Suite("TokenRefreshServiceImpl — 갱신 요청 계약")
    struct TokenRefreshServiceTests {

        // MARK: - Helpers

        private func makeSUT() -> TokenRefreshServiceImpl {
            StubURLProtocol.reset()
            return TokenRefreshServiceImpl(
                baseURL: URL(string: "https://api.test")!,
                session: StubURLProtocol.session()
            )
        }

        private static func response(_ url: URL?, _ code: Int) -> HTTPURLResponse {
            HTTPURLResponse(
                url: url ?? URL(string: "https://api.test")!,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
        }

        private static let successBody = Data(#"{"accessToken":"a","refreshToken":"b"}"#.utf8)

        // MARK: - Tests

        @Test("refresh — POST /auth/refresh, JSON 헤더, 바디는 Authorization 키로 인코딩한다")
        func sendsRefreshTokenUnderAuthorizationBodyKey() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { req in (Self.response(req.url, 200), Self.successBody) }

            _ = try await sut.refresh("rt")

            let captured = try #require(StubURLProtocol.recordedRequests.first)
            #expect(captured.httpMethod == "POST")
            #expect(captured.url?.absoluteString == "https://api.test/auth/refresh")
            #expect(captured.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let json = try #require(JSONSerialization.jsonObject(with: captured.bodyData) as? NSDictionary)
            #expect(json == ["Authorization": "rt"])
        }

        @Test("2xx 응답의 accessToken/refreshToken을 TokenPair로 매핑한다")
        func mapsSuccessResponseToTokenPair() async throws {
            let sut = makeSUT()
            StubURLProtocol.handler = { req in (Self.response(req.url, 200), Self.successBody) }

            let pair = try await sut.refresh("rt")

            #expect(pair == TokenPair(accessToken: "a", refreshToken: "b"))
        }

        /// NetworkClient는 이 상태 코드로 세션 종료(401)와 일시적 실패(5xx)를 가른다.
        @Test("2xx가 아닌 응답은 상태 코드를 담아 serverError로 던진다")
        func throwsServerErrorWithStatusCode() async {
            let sut = makeSUT()
            StubURLProtocol.handler = { req in (Self.response(req.url, 500), Data()) }

            let error = await #expect(throws: TokenRefreshError.self) {
                _ = try await sut.refresh("rt")
            }

            guard case .serverError(let statusCode)? = error else {
                Issue.record("serverError가 아님: \(String(describing: error))")
                return
            }
            #expect(statusCode == 500)
        }
    }
}
