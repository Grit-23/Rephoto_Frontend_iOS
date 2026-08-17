//
//  AlbumResponseDTO.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/19/25.
//

import Foundation

struct AlbumResponseDTO: Codable {
    let tagId: Int
    let tagName: String
    let coverImageUrl: String?
    let photoCount: Int

    func toDomain() -> Album {
        Album(
            tagId: tagId,
            tagName: tagName,
            coverImageUrl: coverImageUrl.flatMap(URL.init(string:)),
            photoCount: photoCount
        )
    }
}
