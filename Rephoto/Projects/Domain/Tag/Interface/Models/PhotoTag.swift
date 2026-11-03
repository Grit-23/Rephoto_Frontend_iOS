//
//  PhotoTag.swift
//  TagDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

public struct PhotoTag: Identifiable, Sendable {
    public let id: Int
    public let photoTagId: Int
    public let tagId: Int
    public let tagName: String
    public let photoId: Int

    public init(photoTagId: Int, tagId: Int, tagName: String, photoId: Int) {
        self.id = photoTagId
        self.photoTagId = photoTagId
        self.tagId = tagId
        self.tagName = tagName
        self.photoId = photoId
    }
}
