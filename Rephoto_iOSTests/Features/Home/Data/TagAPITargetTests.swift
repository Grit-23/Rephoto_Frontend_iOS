//
//  TagAPITargetTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 8/2/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// TagAPITarget의 엔드포인트 계약 검증.
///
/// 태그는 조회만 사진 하위 경로(`/photos/{id}/tags`)를 쓰고 생성·수정·삭제는 `/tags` 계열을 쓴다.
/// 두 경로 체계가 섞여 있어 오타가 나기 쉬운 지점이라 케이스별로 고정한다.
@Suite("TagAPITarget — 엔드포인트 계약")
struct TagAPITargetTests {

    // MARK: - path / method

    @Test("getTags — photoId가 사진 하위 경로에 보간된다", arguments: [1, 42, 9999])
    func getTags(photoId: Int) {
        let target = TagAPITarget.getTags(photoId: photoId)

        #expect(target.path == "/photos/\(photoId)/tags")
        #expect(target.method == .get)
        #expect(target.task.isPlain)
    }

    @Test("addTag — POST /tags")
    func addTagPathAndMethod() {
        let target = TagAPITarget.addTag(request: AddTagRequestDTO(photoId: 1, tagName: "바다"))

        #expect(target.path == "/tags")
        #expect(target.method == .post)
    }

    @Test("updateTag — photoTagId가 path에 보간된다", arguments: [1, 42, 9999])
    func updateTag(photoTagId: Int) {
        let target = TagAPITarget.updateTag(
            photoTagId: photoTagId,
            request: UpdateTagRequestDTO(tagName: "노을")
        )

        #expect(target.path == "/tags/\(photoTagId)")
        #expect(target.method == .put)
    }

    @Test("deleteTag — photoTagId가 path에 보간된다", arguments: [1, 42, 9999])
    func deleteTag(photoTagId: Int) {
        let target = TagAPITarget.deleteTag(photoTagId: photoTagId)

        #expect(target.path == "/tags/\(photoTagId)")
        #expect(target.method == .delete)
        #expect(target.task.isPlain)
    }

    // MARK: - task

    @Test("addTag — photoId와 tagName을 JSON 바디로 싣는다")
    func addTagCarriesPhotoIdAndTagName() throws {
        let target = TagAPITarget.addTag(request: AddTagRequestDTO(photoId: 7, tagName: "바다"))

        let body = try #require(target.task.jsonBody(as: AddTagRequestDTO.self), "task가 .jsonEncodable이 아님")
        #expect(body.photoId == 7)
        #expect(body.tagName == "바다")
    }

    /// updateTag의 식별자는 path로만 전달된다 — 바디에는 tagName만 실린다.
    @Test("updateTag — 바디에는 tagName만 싣고 식별자는 path로 전달한다")
    func updateTagCarriesOnlyTagName() throws {
        let target = TagAPITarget.updateTag(
            photoTagId: 7,
            request: UpdateTagRequestDTO(tagName: "노을")
        )

        let body = try #require(target.task.jsonBody(as: UpdateTagRequestDTO.self), "task가 .jsonEncodable이 아님")
        #expect(body.tagName == "노을")
    }

    // MARK: - headers

    @Test("모든 케이스가 JSON 기본 헤더를 사용한다")
    func allCasesUseJSONHeader() {
        let targets: [TagAPITarget] = [
            .getTags(photoId: 1),
            .addTag(request: AddTagRequestDTO(photoId: 1, tagName: "바다")),
            .updateTag(photoTagId: 1, request: UpdateTagRequestDTO(tagName: "노을")),
            .deleteTag(photoTagId: 1)
        ]

        for target in targets {
            #expect(target.headers == ["Content-Type": "application/json"])
        }
    }
}
