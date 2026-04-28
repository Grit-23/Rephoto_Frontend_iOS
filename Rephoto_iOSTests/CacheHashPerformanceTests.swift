//
//  CacheHashPerformanceTests.swift
//  Rephoto_iOSTests
//
//  캐시/변경 감지 성능 벤치마크
//  리팩토링 항목 #5: 현재는 매번 전체 API 호출
//  현재 코드의 fetchPhotos() → 전체 디코딩 → 전체 교체 비용 측정
//

import XCTest
@testable import Rephoto_iOS

final class CacheHashPerformanceTests: XCTestCase {

    /// 현재 방식: 전체 사진 목록을 매번 새로 받아서 교체 (1000개)
    func test_fullReplace_1000() {
        let data = MockDataFactory.photosJSONData(count: 1000)

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // 현재 fetchPhotos(): 전체 디코딩 + 전체 매핑 + 배열 교체
            let dtos = try! JSONDecoder().decode([PhotoResponseDto].self, from: data)
            let models = dtos.map { $0.toHomeModel() }
            var images: [HomeModel] = []
            images = models  // 전체 교체
            XCTAssertEqual(images.count, 1000)
        }
    }

    /// 현재 방식: 전체 사진 목록 교체 (500개)
    func test_fullReplace_500() {
        let data = MockDataFactory.photosJSONData(count: 500)

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let dtos = try! JSONDecoder().decode([PhotoResponseDto].self, from: data)
            let models = dtos.map { $0.toHomeModel() }
            var images: [HomeModel] = []
            images = models
            XCTAssertEqual(images.count, 500)
        }
    }
}
