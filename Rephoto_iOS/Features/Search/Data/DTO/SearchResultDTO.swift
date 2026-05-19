//
//  SearchResultDTO.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/16/25.
//

import Foundation

struct SearchResultDTO: Codable {
    let imageUrl: URL
    let photoId: Int

    func toDomain() -> SearchResult {
        SearchResult(imageUrl: imageUrl, photoId: photoId)
    }
}
