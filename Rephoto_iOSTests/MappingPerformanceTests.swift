//
//  MappingPerformanceTests.swift
//  Rephoto_iOSTests
//
//  DTO → Domain Model 매핑 성능 벤치마크
//

import XCTest
@testable import Rephoto_iOS

final class MappingPerformanceTests: XCTestCase {

    // MARK: - PhotoResponseDto → HomeModel 매핑

    /// 100개 사진 DTO → HomeModel 변환 성능
    /// DateFormatter 생성 + 날짜 파싱이 포함되므로 병목 가능성 있음
    func test_mapToHomeModel_100() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 100)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = dtos.map { $0.toHomeModel() }
        }
    }

    /// 500개 사진 DTO → HomeModel 변환 성능
    func test_mapToHomeModel_500() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 500)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = dtos.map { $0.toHomeModel() }
        }
    }

    /// 1000개 사진 DTO → HomeModel 변환 성능
    func test_mapToHomeModel_1000() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 1000)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = dtos.map { $0.toHomeModel() }
        }
    }

    // MARK: - 전체 파이프라인 (디코딩 + 매핑)

    /// JSON Data → [PhotoResponseDto] → [HomeModel] 전체 파이프라인
    func test_fullPipeline_decodeAndMap_100() throws {
        let data = MockDataFactory.photosJSONData(count: 100)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            guard let dtos = try? JSONDecoder().decode([PhotoResponseDto].self, from: data) else { return }
            _ = dtos.map { $0.toHomeModel() }
        }
    }

    func test_fullPipeline_decodeAndMap_500() throws {
        let data = MockDataFactory.photosJSONData(count: 500)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            guard let dtos = try? JSONDecoder().decode([PhotoResponseDto].self, from: data) else { return }
            _ = dtos.map { $0.toHomeModel() }
        }
    }

    // MARK: - isSensitive 필터링 성능

    /// HomeModel 배열에서 민감한 사진 필터링
    func test_filterSensitivePhotos_1000() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 1000)
        let models = dtos.map { $0.toHomeModel() }
        measure(metrics: [XCTClockMetric()]) {
            _ = models.filter { $0.isSensitive == false }
            _ = models.filter { $0.isSensitive }
            _ = models.count(where: { $0.isSensitive })
        }
    }
}
