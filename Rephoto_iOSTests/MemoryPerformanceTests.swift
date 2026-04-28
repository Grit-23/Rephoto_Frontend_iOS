//
//  MemoryPerformanceTests.swift
//  Rephoto_iOSTests
//
//  메모리 사용량 벤치마크
//

import XCTest
@testable import Rephoto_iOS

final class MemoryPerformanceTests: XCTestCase {

    /// HomeModel 배열 대량 생성 시 메모리 사용량
    func test_memoryFootprint_homeModels_1000() {
        measure(metrics: [XCTMemoryMetric()]) {
            let dtos = MockDataFactory.photoResponseDTOs(count: 1000)
            let models = dtos.map { $0.toHomeModel() }
            // 메모리에 유지되도록 강제
            XCTAssertEqual(models.count, 1000)
        }
    }

    /// SearchResults 대량 생성 시 메모리 사용량
    func test_memoryFootprint_searchResults_500() {
        let data = MockDataFactory.searchResponseJSON(resultCount: 500)
        measure(metrics: [XCTMemoryMetric()]) {
            let decoded = try? JSONDecoder().decode(SearchResponseDto.self, from: data)
            XCTAssertEqual(decoded?.searchResults.count, 500)
        }
    }

    /// 전체 파이프라인 메모리 피크: JSON → DTO → Model (중간 객체 포함)
    func test_memoryPeak_fullPipeline_1000() {
        let data = MockDataFactory.photosJSONData(count: 1000)
        measure(metrics: [XCTMemoryMetric(), XCTClockMetric()]) {
            // 레거시에서는 DTO 배열과 Model 배열이 동시에 메모리에 존재
            let dtos = try! JSONDecoder().decode([PhotoResponseDto].self, from: data)
            let models = dtos.map { $0.toHomeModel() }
            XCTAssertEqual(models.count, 1000)
        }
    }
}
