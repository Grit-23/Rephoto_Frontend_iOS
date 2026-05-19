//
//  AlbumResponseDTO.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/19/25.
//

import Foundation

struct AlbumResponseDTO: Codable {
    let userId: Int
    let tagId: Int
    let tagName: String

    func toDomain() -> Album {
        Album(tagId: tagId, tagName: tagName)
    }
}
