//
//  AlbumAPITargetTests.swift
//  AlbumDomainTests
//
//  Created by Doyeon Kim on 8/2/26.
//

import Foundation
import Testing
import NetworkAdapter
import NetworkAdapterTesting
@testable import AlbumDomain

/// AlbumAPITarget의 엔드포인트 계약 검증.
///
/// 앨범 상세(`/albums/{tagId}/photos`)는 사진 목록을 반환하므로 PhotoDomain의 `PhotosAPITarget`이 맡는다.
@Suite("AlbumAPITarget — 엔드포인트 계약")
struct AlbumAPITargetTests {

    @Test("getAlbumList — GET /albums")
    func getAlbumList() {
        let target = AlbumAPITarget.getAlbumList

        #expect(target.path == "/albums")
        #expect(target.method == .get)
        #expect(target.task.isPlain)
    }

    @Test("JSON 기본 헤더를 사용한다")
    func usesJSONHeader() {
        #expect(AlbumAPITarget.getAlbumList.headers == ["Content-Type": "application/json"])
    }
}
