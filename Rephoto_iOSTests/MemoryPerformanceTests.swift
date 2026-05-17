//
//  MemoryPerformanceTests.swift
//  Rephoto_iOSTests
//
//  메모리 사용량 벤치마크
//

import XCTest
@testable import Rephoto_iOS

final class MemoryPerformanceTests: XCTestCase {

    // measure 블록 종료 후에도 객체를 retain하여 메모리 delta 측정
    private var retainedModels: [Photo] = []
    private var retainedSearchResult: SearchResponseDto?
    private var retainedDtos: [PhotoResponseDTO] = []

    override func tearDown() {
        retainedModels = []
        retainedSearchResult = nil
        retainedDtos = []
        super.tearDown()
    }

    /// Photo 배열 대량 생성 시 메모리 사용량
    func test_memoryFootprint_homeModels_1000() {
        measure(metrics: [XCTMemoryMetric()]) {
            let dtos = MockDataFactory.photoResponseDTOs(count: 1000)
            retainedModels = dtos.map { try! $0.toDomain() }
            XCTAssertEqual(retainedModels.count, 1000)
        }
    }

    /// SearchResults 대량 생성 시 메모리 사용량
    func test_memoryFootprint_searchResults_500() {
        let data = MockDataFactory.searchResponseJSON(resultCount: 500)
        measure(metrics: [XCTMemoryMetric()]) {
            retainedSearchResult = try? JSONDecoder().decode(SearchResponseDto.self, from: data)
            XCTAssertEqual(retainedSearchResult?.searchResults.count, 500)
        }
    }

    /// 전체 파이프라인 메모리 피크: JSON → DTO → Model (중간 객체 포함)
    func test_memoryPeak_fullPipeline_1000() {
        let data = MockDataFactory.photosJSONData(count: 1000)
        measure(metrics: [XCTMemoryMetric(), XCTClockMetric()]) {
            // 레거시에서는 DTO 배열과 Model 배열이 동시에 메모리에 존재
            retainedDtos = try! JSONDecoder().decode([PhotoResponseDTO].self, from: data)
            retainedModels = retainedDtos.map { try! $0.toDomain() }
            XCTAssertEqual(retainedModels.count, 1000)
        }
    }
}
