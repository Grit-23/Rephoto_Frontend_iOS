//
//  PhotoInfoPerformanceTests.swift
//  Rephoto_iOSTests
//
//  사진 정보(태그) 처리 성능 벤치마크
//  Step 7 Dictionary 기반 O(1) 태그 조회 전환 시 비교용 baseline
//

import XCTest
@testable import Rephoto_iOS

final class PhotoInfoPerformanceTests: XCTestCase {

    // MARK: - 태그 JSON 헬퍼

    private func makeTagsJSON(count: Int, photoId: Int = 42) -> Data {
        let tags: [[String: Any]] = (1...count).map { i in
            [
                "photoTagId": i,
                "tagId": i * 10,
                "tagName": "태그_\(i)",
                "photoId": photoId
            ]
        }
        return try! JSONSerialization.data(withJSONObject: tags)
    }

    // MARK: - Optimistic UI: 태그 배열 검색 + 교체 (현재 updateTag 방식)

    /// firstIndex(where:)로 태그 찾기 + 교체 (10개 중)
    func test_optimisticTagUpdate_in10() {
        let data = makeTagsJSON(count: 10)
        var tags = try! JSONDecoder().decode([TagResponseDTO].self, from: data)

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<1000 {
                let targetId = tags[tags.count / 2].photoTagId
                if let index = tags.firstIndex(where: { $0.photoTagId == targetId }) {
                    tags[index] = TagResponseDTO(
                        photoTagId: tags[index].photoTagId,
                        tagId: tags[index].tagId,
                        tagName: "수정됨",
                        photoId: tags[index].photoId
                    )
                }
            }
        }
    }

    /// firstIndex(where:)로 태그 찾기 + 교체 (100개 중)
    func test_optimisticTagUpdate_in100() {
        let data = makeTagsJSON(count: 100)
        var tags = try! JSONDecoder().decode([TagResponseDTO].self, from: data)

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<1000 {
                let targetId = tags[tags.count - 1].photoTagId  // 최악: 마지막 요소
                if let index = tags.firstIndex(where: { $0.photoTagId == targetId }) {
                    tags[index] = TagResponseDTO(
                        photoTagId: tags[index].photoTagId,
                        tagId: tags[index].tagId,
                        tagName: "수정됨",
                        photoId: tags[index].photoId
                    )
                }
            }
        }
    }
}
