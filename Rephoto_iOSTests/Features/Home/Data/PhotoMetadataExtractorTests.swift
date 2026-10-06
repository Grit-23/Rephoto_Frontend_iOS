//
//  PhotoMetadataExtractorTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 10/6/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// 업로드용 다운샘플 목표 크기 계산 검증.
///
/// 목표 크기는 원본 긴 변을 반씩 나눠 JPEG 1/2ⁿ 디코드 경계에 맞추되(#49),
/// 정렬값이 하한보다 작으면 상한을 요청한다(#88). 순수 계산이라 값으로 고정한다.
@Suite("PhotoMetadataExtractor — 다운샘플 목표 크기")
struct PhotoMetadataExtractorTests {

    @Test(
        "원본 긴 변에 따라 목표 크기를 정한다",
        arguments: [
            // 경계 정렬을 유지하는 크기
            (4032, 2016),   // 12MP → 1/2
            (8064, 2016),   // 48MP → 1/4
            (3072, 1536),   // 정렬값이 하한과 같으면 유지
            // 정렬값이 하한(1536) 미만이면 상한(2048)을 요청
            (5712, 2048),   // 24MP — 정렬하면 1428
            (3000, 2048),   // 정렬하면 1500
            (2049, 2048),   // 정렬하면 1024.5
            // 상한 이하 원본은 그대로
            (2048, 2048),
            (1200, 1200),
            // 크기를 읽지 못하면 대비값
            (0, 2016),
        ]
    )
    func targetPixelSize(longerSide: Int, expected: Int) {
        #expect(PhotoMetadataExtractor.targetPixelSize(forLongerSide: longerSide) == CGFloat(expected))
    }
}
