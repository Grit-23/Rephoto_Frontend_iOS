//
//  AlbumResponseDTOTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 8/18/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// `GET /albums` 응답 계약 검증.
///
/// 앨범 목록 N+1 제거(#66)로 응답에 `coverImageUrl`·`photoCount`가 추가됐다. 이 두 필드는
/// 카드 프리뷰를 채우던 앨범별 추가 요청을 대체하므로, 계약이 깨지면 목록 화면이 통째로 빈다.
/// `AlbumRepository`가 기본 설정 `JSONDecoder()`로 `[AlbumResponseDTO]`를 디코드하므로
/// 키 변환 없이 camelCase 그대로 고정한다.
@Suite("AlbumResponseDTO — 응답 계약")
struct AlbumResponseDTOTests {

    private let decoder = JSONDecoder()

    private func decode(_ json: String) throws -> [AlbumResponseDTO] {
        try decoder.decode([AlbumResponseDTO].self, from: Data(json.utf8))
    }

    @Test("전체 필드를 디코드해 도메인으로 매핑한다")
    func decodesFullPayload() throws {
        let dtos = try decode("""
        [{
            "tagId": 7,
            "tagName": "커피",
            "coverImageUrl": "https://example.com/cover.jpg",
            "photoCount": 12
        }]
        """)

        let album = try #require(dtos.first).toDomain()

        #expect(album.tagId == 7)
        #expect(album.tagName == "커피")
        #expect(album.coverImageUrl == URL(string: "https://example.com/cover.jpg"))
        #expect(album.photoCount == 12)
        // id는 tagId를 그대로 노출한다 — NavigationLink 값/ForEach identity가 여기 의존한다
        #expect(album.id == 7)
    }

    @Test("coverImageUrl이 null이면 nil로 매핑된다 — 사진이 없는 앨범")
    func decodesNullCoverImageUrl() throws {
        let dtos = try decode("""
        [{ "tagId": 1, "tagName": "빈앨범", "coverImageUrl": null, "photoCount": 0 }]
        """)

        let album = try #require(dtos.first).toDomain()

        #expect(album.coverImageUrl == nil)
        #expect(album.photoCount == 0)
    }

    @Test("coverImageUrl 키가 아예 없어도 디코딩은 성공한다")
    func decodesMissingCoverImageUrl() throws {
        let dtos = try decode("""
        [{ "tagId": 1, "tagName": "빈앨범", "photoCount": 0 }]
        """)

        #expect(try #require(dtos.first).toDomain().coverImageUrl == nil)
    }

    @Test("URL로 만들 수 없는 coverImageUrl은 nil로 떨어진다")
    func mapsInvalidCoverImageUrlToNil() throws {
        let dtos = try decode("""
        [{ "tagId": 1, "tagName": "커피", "coverImageUrl": "", "photoCount": 3 }]
        """)

        // 빈 문자열은 URL(string:)이 nil을 반환한다 — 디코딩을 실패시키지 않고 커버만 비운다
        #expect(try #require(dtos.first).toDomain().coverImageUrl == nil)
    }

    /// photoCount는 옵셔널이 아니므로 누락 시 배열 전체 디코딩이 실패한다.
    /// 부분 실패가 아니라 앨범 목록이 통째로 비게 되므로, 이 강한 결합을 테스트로 고정해 둔다.
    @Test("photoCount가 누락되면 디코딩이 실패한다")
    func failsWhenPhotoCountMissing() {
        #expect(throws: DecodingError.self) {
            try decode("""
            [{ "tagId": 1, "tagName": "커피", "coverImageUrl": null }]
            """)
        }
    }

    @Test("응답에 없는 필드는 무시한다 — 서버가 필드를 추가해도 깨지지 않는다")
    func ignoresUnknownFields() throws {
        let dtos = try decode("""
        [{
            "tagId": 1,
            "tagName": "커피",
            "coverImageUrl": null,
            "photoCount": 3,
            "userId": 99,
            "createdAt": "2026-08-18T00:00:00Z"
        }]
        """)

        #expect(dtos.count == 1)
        #expect(try #require(dtos.first).toDomain().photoCount == 3)
    }
}
