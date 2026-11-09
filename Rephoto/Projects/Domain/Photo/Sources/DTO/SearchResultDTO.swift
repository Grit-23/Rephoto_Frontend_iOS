//
//  SearchResultDTO.swift
//  PhotoDomain
//
//  Created by 김도연 on 8/16/25.
//

import Foundation
import PhotoDomainInterface

struct SearchResultDTO: Decodable {
    let imageUrl: URL
    let photoId: Int

    func toDomain() -> SearchResult {
        SearchResult(imageUrl: imageUrl, photoId: photoId)
    }
}
