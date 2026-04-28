//
//  MockDataFactory.swift
//  Rephoto_iOSTests
//
//  성능 벤치마크용 Mock 데이터 생성
//

import Foundation
@testable import Rephoto_iOS

enum MockDataFactory {

    // MARK: - Photo JSON

    /// 단일 사진 JSON 딕셔너리
    static func photoJSON(id: Int) -> [String: Any] {
        [
            "photoId": id,
            "imageUrl": "https://example.com/photos/photo_\(id).jpg",
            "latitude": 37.5665 + (Double((id % 11) - 5) * 0.01),
            "longitude": 126.9780 + (Double((id % 11) - 5) * 0.01),
            "createdAt": "2025-07-\(String(format: "%02d", (id % 28) + 1))T12:00:00",
            "fileName": "IMG_\(id).jpg",
            "tags": ["풍경", "서울", "여행"],
            "private": id % 5 == 0
        ]
    }

    /// N개의 사진 JSON Data
    static func photosJSONData(count: Int) -> Data {
        guard count > 0 else { return Data("[]".utf8) }
        let array = (1...count).map { photoJSON(id: $0) }
        return try! JSONSerialization.data(withJSONObject: array)
    }

    // MARK: - Search JSON

    static func searchResponseJSON(resultCount: Int) -> Data {
        guard resultCount > 0 else {
            let response: [String: Any] = ["query": "테스트 검색어", "searchResults": []]
            return try! JSONSerialization.data(withJSONObject: response)
        }
        let results: [[String: Any]] = (1...resultCount).map { i in
            [
                "imageUrl": "https://example.com/photos/search_\(i).jpg",
                "photoId": i
            ]
        }
        let response: [String: Any] = [
            "query": "테스트 검색어",
            "searchResults": results
        ]
        return try! JSONSerialization.data(withJSONObject: response)
    }

    // MARK: - Album JSON

    static func albumListJSON(count: Int) -> Data {
        guard count > 0 else { return Data("[]".utf8) }
        let albums: [[String: Any]] = (1...count).map { i in
            [
                "userId": 1,
                "tagId": i,
                "tagName": "앨범_\(i)"
            ]
        }
        return try! JSONSerialization.data(withJSONObject: albums)
    }

    // MARK: - Pre-decoded DTOs

    static func photoResponseDTOs(count: Int) -> [PhotoResponseDto] {
        let data = photosJSONData(count: count)
        return try! JSONDecoder().decode([PhotoResponseDto].self, from: data)
    }
}
