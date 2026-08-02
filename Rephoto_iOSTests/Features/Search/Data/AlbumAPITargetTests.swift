//
//  AlbumAPITargetTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 8/2/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// AlbumAPITarget의 엔드포인트 계약 검증.
///
/// 앨범 상세는 앨범 자체가 아니라 사진 목록을 반환하므로 경로가 `/albums/{tagId}/photos`로 끝난다.
/// 또한 경로 파라미터가 albumId가 아니라 tagId라는 점을 함께 고정한다.
@Suite("AlbumAPITarget — 엔드포인트 계약")
struct AlbumAPITargetTests {

    @Test("getAlbumList — GET /albums")
    func getAlbumList() {
        let target = AlbumAPITarget.getAlbumList

        #expect(target.path == "/albums")
        #expect(target.method == .get)
        #expect(target.task.isPlain)
    }

    @Test("getAlbumInfo — tagId가 path에 보간되고 /photos로 끝난다", arguments: [1, 42, 9999])
    func getAlbumInfo(tagId: Int) {
        let target = AlbumAPITarget.getAlbumInfo(tagId: tagId)

        #expect(target.path == "/albums/\(tagId)/photos")
        #expect(target.method == .get)
        #expect(target.task.isPlain)
    }

    @Test("모든 케이스가 JSON 기본 헤더를 사용한다")
    func allCasesUseJSONHeader() {
        let targets: [AlbumAPITarget] = [.getAlbumList, .getAlbumInfo(tagId: 1)]

        for target in targets {
            #expect(target.headers == ["Content-Type": "application/json"])
        }
    }
}
