//
//  SearchAPITargetTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 8/2/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// SearchAPITarget의 엔드포인트 계약 검증.
///
/// 검색은 자연어 질의를 URL이 아닌 JSON 바디로 보낸다 — 길이 제한과 인코딩 이슈를 피하기 위함.
/// 쿼리스트링으로 되돌아가지 않도록 POST + 바디 구성을 함께 고정한다.
@Suite("SearchAPITarget — 엔드포인트 계약")
struct SearchAPITargetTests {

    @Test("search — POST /search")
    func searchPathAndMethod() {
        let target = SearchAPITarget.search(query: "제주도 바다")

        #expect(target.path == "/search")
        #expect(target.method == .post)
    }

    @Test(
        "search — query를 SearchRequestDTO 바디로 감싼다",
        arguments: ["제주도 바다", "노을 지는 하늘", "cafe & 디저트"]
    )
    func searchWrapsQueryInBody(query: String) throws {
        let target = SearchAPITarget.search(query: query)

        let body = try #require(target.task.jsonBody(as: SearchRequestDTO.self), "task가 .jsonEncodable이 아님")
        #expect(body.query == query)
    }

    /// 질의어는 path에 섞이지 않아야 한다 — 공백/특수문자 인코딩 사고를 막는 계약.
    @Test("search — query가 path에 섞이지 않는다")
    func searchKeepsQueryOutOfPath() {
        #expect(SearchAPITarget.search(query: "cafe & 디저트").path == "/search")
    }

    @Test("search — JSON 기본 헤더를 사용한다")
    func searchUsesJSONHeader() {
        #expect(SearchAPITarget.search(query: "바다").headers == ["Content-Type": "application/json"])
    }
}
