//
//  TagDTO.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

struct TagResponseDTO: Decodable {
    let photoTagId: Int
    let tagId: Int
    let tagName: String
    let photoId: Int

    func toDomain() -> PhotoTag {
        PhotoTag(photoTagId: photoTagId, tagId: tagId, tagName: tagName, photoId: photoId)
    }
}

struct AddTagRequestDTO: Encodable {
    let photoId: Int
    let tagName: String
}

struct UpdateTagRequestDTO: Encodable {
    let tagName: String
}
