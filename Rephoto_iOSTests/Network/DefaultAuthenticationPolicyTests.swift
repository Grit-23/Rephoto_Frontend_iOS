//
//  DefaultAuthenticationPolicyTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// 인증 정책의 경로 판정과 401 판정 검증
@Suite("DefaultAuthenticationPolicy")
struct DefaultAuthenticationPolicyTests {

    private let policy = DefaultAuthenticationPolicy()

    private func request(path: String) -> URLRequest {
        URLRequest(url: URL(string: "https://api.test\(path)")!)
    }

    @Test("공개 경로는 인증이 필요 없다", arguments: ["/login", "/join", "/auth/refresh"])
    func publicPathDoesNotRequireAuthentication(path: String) {
        #expect(!policy.requireAuthentication(request(path: path)))
    }

    @Test(
        "보호 경로는 인증이 필요하다",
        arguments: ["/photos", "/photos/1/tags", "/users", "/search", "/albums", "/logout"]
    )
    func protectedPathRequiresAuthentication(path: String) {
        #expect(policy.requireAuthentication(request(path: path)))
    }

    /// 공개 경로 판정은 suffix 매칭이므로, 유사 경로가 공개로 오인되면 안 된다.
    @Test("공개 경로와 비슷한 경로는 보호 경로로 판정한다", arguments: ["/relogin", "/joint", "/auth/refresh2"])
    func lookalikePathStillRequiresAuthentication(path: String) {
        #expect(policy.requireAuthentication(request(path: path)))
    }

    @Test(
        "401 상태코드만 unauthorized로 판정한다",
        arguments: [
            (200, false),
            (204, false),
            (400, false),
            (401, true),
            (403, false),
            (404, false),
            (500, false),
        ]
    )
    func only401IsUnauthorized(statusCode: Int, expected: Bool) throws {
        let response = try #require(
            HTTPURLResponse(
                url: URL(string: "https://api.test/photos")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
        )

        #expect(policy.isUnauthorizedResponse(response) == expected)
    }
}
