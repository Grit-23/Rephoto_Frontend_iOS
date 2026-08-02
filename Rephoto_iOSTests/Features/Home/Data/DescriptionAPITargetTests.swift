//
//  DescriptionAPITargetTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 8/2/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// DescriptionAPITarget의 엔드포인트 계약 검증.
@Suite("DescriptionAPITarget — 엔드포인트 계약")
struct DescriptionAPITargetTests {

    @Test("getDescription — photoId가 path에 보간된다", arguments: [1, 42, 9999])
    func getDescription(photoId: Int) {
        let target = DescriptionAPITarget.getDescription(photoId: photoId)

        #expect(target.path == "/photos/\(photoId)/description")
        #expect(target.method == .get)
        #expect(target.task.isPlain)
    }

    @Test("getDescription — JSON 기본 헤더를 사용한다")
    func getDescriptionUsesJSONHeader() {
        #expect(DescriptionAPITarget.getDescription(photoId: 1).headers == ["Content-Type": "application/json"])
    }
}
