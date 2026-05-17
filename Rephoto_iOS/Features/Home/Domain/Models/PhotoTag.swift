//
//  PhotoTag.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

struct PhotoTag: Identifiable {
    let id: Int
    let photoTagId: Int
    let tagId: Int
    let tagName: String
    let photoId: Int

    init(photoTagId: Int, tagId: Int, tagName: String, photoId: Int) {
        self.id = photoTagId
        self.photoTagId = photoTagId
        self.tagId = tagId
        self.tagName = tagName
        self.photoId = photoId
    }
}
