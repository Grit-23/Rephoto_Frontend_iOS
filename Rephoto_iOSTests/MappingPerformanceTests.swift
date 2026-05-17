//
//  MappingPerformanceTests.swift
//  Rephoto_iOSTests
//
//  DTO → Domain Model 매핑 성능 벤치마크
//

import XCTest
@testable import Rephoto_iOS

final class MappingPerformanceTests: XCTestCase {

    // MARK: - PhotoResponseDTO → Photo 매핑

    /// 100개 사진 DTO → Photo 변환 성능
    /// DateFormatter 생성 + 날짜 파싱이 포함되므로 병목 가능성 있음
    func test_mapToPhoto_100() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 100)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = dtos.map { try! $0.toDomain() }
        }
    }

    /// 500개 사진 DTO → Photo 변환 성능
    func test_mapToPhoto_500() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 500)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = dtos.map { try! $0.toDomain() }
        }
    }

    /// 1000개 사진 DTO → Photo 변환 성능
    func test_mapToPhoto_1000() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 1000)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = dtos.map { try! $0.toDomain() }
        }
    }

    // MARK: - 전체 파이프라인 (디코딩 + 매핑)

    /// JSON Data → [PhotoResponseDTO] → [Photo] 전체 파이프라인
    func test_fullPipeline_decodeAndMap_100() throws {
        let data = MockDataFactory.photosJSONData(count: 100)
        let decoder = JSONDecoder()
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            do {
                let dtos = try decoder.decode([PhotoResponseDTO].self, from: data)
                _ = dtos.map { try! $0.toDomain() }
            } catch {
                XCTFail("Decode failed: \(error)")
            }
        }
    }

    func test_fullPipeline_decodeAndMap_500() throws {
        let data = MockDataFactory.photosJSONData(count: 500)
        let decoder = JSONDecoder()
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            do {
                let dtos = try decoder.decode([PhotoResponseDTO].self, from: data)
                _ = dtos.map { try! $0.toDomain() }
            } catch {
                XCTFail("Decode failed: \(error)")
            }
        }
    }

    // MARK: - isSensitive 필터링 성능

    /// Photo 배열에서 비민감 사진 필터링
    func test_filterNonSensitivePhotos_1000() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 1000)
        let models = dtos.map { try! $0.toDomain() }
        measure(metrics: [XCTClockMetric()]) {
            _ = models.filter { $0.isSensitive == false }
        }
    }

    /// Photo 배열에서 민감한 사진 필터링
    func test_filterSensitivePhotos_1000() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 1000)
        let models = dtos.map { try! $0.toDomain() }
        measure(metrics: [XCTClockMetric()]) {
            _ = models.filter { $0.isSensitive }
        }
    }

    /// Photo 배열에서 민감한 사진 카운트
    func test_countSensitivePhotos_1000() throws {
        let dtos = MockDataFactory.photoResponseDTOs(count: 1000)
        let models = dtos.map { try! $0.toDomain() }
        measure(metrics: [XCTClockMetric()]) {
            _ = models.count(where: { $0.isSensitive })
        }
    }
}
