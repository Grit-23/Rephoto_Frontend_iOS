//
//  PhotoInfoPerformanceTests.swift
//  Rephoto_iOSTests
//
//  사진 정보(태그/설명) 처리 성능 벤치마크
//  리팩토링 항목 #6: 사진 정보 수정
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

    private func makeTagRequestJSON(tagName: String) -> Data {
        let request = TagRequestDto(tagName: tagName)
        return try! JSONEncoder().encode(request)
    }

    // MARK: - 태그 디코딩

    /// 태그 10개 디코딩 (일반적인 사진)
    func test_decodeTags_10() {
        let data = makeTagsJSON(count: 10)
        measure(metrics: [XCTClockMetric()]) {
            _ = try? JSONDecoder().decode([TagResponseDto].self, from: data)
        }
    }

    /// 태그 100개 디코딩 (대량 태그)
    func test_decodeTags_100() {
        let data = makeTagsJSON(count: 100)
        measure(metrics: [XCTClockMetric()]) {
            _ = try? JSONDecoder().decode([TagResponseDto].self, from: data)
        }
    }

    // MARK: - 태그 요청 인코딩

    /// 태그 추가/수정 요청 인코딩 1000회
    func test_encodeTagRequest_1000() {
        measure(metrics: [XCTClockMetric()]) {
            let encoder = JSONEncoder()
            for i in 0..<1000 {
                let request = TagRequestDto(tagName: "새태그_\(i)")
                _ = try! encoder.encode(request)
            }
        }
    }

    // MARK: - Optimistic UI: 태그 배열 검색 + 교체 (현재 updateTag 방식)

    /// firstIndex(where:)로 태그 찾기 + 교체 (10개 중)
    func test_optimisticTagUpdate_in10() {
        let data = makeTagsJSON(count: 10)
        var tags = try! JSONDecoder().decode([TagResponseDto].self, from: data)

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<1000 {
                let targetId = tags[tags.count / 2].photoTagId
                if let index = tags.firstIndex(where: { $0.photoTagId == targetId }) {
                    tags[index] = TagResponseDto(
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
        var tags = try! JSONDecoder().decode([TagResponseDto].self, from: data)

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<1000 {
                let targetId = tags[tags.count - 1].photoTagId  // 최악: 마지막 요소
                if let index = tags.firstIndex(where: { $0.photoTagId == targetId }) {
                    tags[index] = TagResponseDto(
                        photoTagId: tags[index].photoTagId,
                        tagId: tags[index].tagId,
                        tagName: "수정됨",
                        photoId: tags[index].photoId
                    )
                }
            }
        }
    }

    // MARK: - 태그 append 성능

    /// 태그 추가 (append) 1000회
    func test_tagAppend_1000() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            var tags: [TagResponseDto] = []
            for i in 0..<1000 {
                tags.append(TagResponseDto(
                    photoTagId: i, tagId: i * 10,
                    tagName: "태그_\(i)", photoId: 42
                ))
            }
            XCTAssertEqual(tags.count, 1000)
        }
    }

    // MARK: - Description (plain text) 파싱

    /// 설명 텍스트 trim 처리 1000회
    func test_descriptionTrimming_1000() {
        let rawTexts = (0..<1000).map { i in
            "  \n  이 사진은 서울 한강에서 촬영된 풍경 사진입니다. 촬영 시각은 오후 3시이며 날씨가 맑았습니다. #\(i)  \n\n  "
        }

        measure(metrics: [XCTClockMetric()]) {
            for text in rawTexts {
                _ = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
}
