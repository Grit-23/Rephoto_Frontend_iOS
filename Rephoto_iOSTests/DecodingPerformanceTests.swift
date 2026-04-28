//
//  DecodingPerformanceTests.swift
//  Rephoto_iOSTests
//
//  JSON 디코딩 성능 벤치마크
//

import XCTest
@testable import Rephoto_iOS

final class DecodingPerformanceTests: XCTestCase {

    // MARK: - PhotoResponseDto 디코딩

    /// 사진 10개 디코딩 성능
    func test_decodePhotos_10() throws {
        let data = MockDataFactory.photosJSONData(count: 10)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = try? JSONDecoder().decode([PhotoResponseDto].self, from: data)
        }
    }

    /// 사진 100개 디코딩 성능
    func test_decodePhotos_100() throws {
        let data = MockDataFactory.photosJSONData(count: 100)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = try? JSONDecoder().decode([PhotoResponseDto].self, from: data)
        }
    }

    /// 사진 500개 디코딩 성능 (대량 데이터)
    func test_decodePhotos_500() throws {
        let data = MockDataFactory.photosJSONData(count: 500)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = try? JSONDecoder().decode([PhotoResponseDto].self, from: data)
        }
    }

    /// 사진 1000개 디코딩 성능 (스트레스 테스트)
    func test_decodePhotos_1000() throws {
        let data = MockDataFactory.photosJSONData(count: 1000)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = try? JSONDecoder().decode([PhotoResponseDto].self, from: data)
        }
    }

    // MARK: - SearchResponseDto 디코딩

    /// 검색 결과 50개 디코딩 성능
    func test_decodeSearchResponse_50() throws {
        let data = MockDataFactory.searchResponseJSON(resultCount: 50)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = try? JSONDecoder().decode(SearchResponseDto.self, from: data)
        }
    }

    /// 검색 결과 200개 디코딩 성능
    func test_decodeSearchResponse_200() throws {
        let data = MockDataFactory.searchResponseJSON(resultCount: 200)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = try? JSONDecoder().decode(SearchResponseDto.self, from: data)
        }
    }

    // MARK: - AlbumResponseDto 디코딩

    /// 앨범 리스트 20개 디코딩 성능
    func test_decodeAlbumList_20() throws {
        let data = MockDataFactory.albumListJSON(count: 20)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = try? JSONDecoder().decode([AlbumResponseDto].self, from: data)
        }
    }
}
