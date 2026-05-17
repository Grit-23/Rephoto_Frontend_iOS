//
//  Photo.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

struct Photo: Identifiable, Hashable {
    let id: UUID
    let photoId: Int
    let imageUrl: URL
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    let fileName: String
    let tags: [String]
    let isSensitive: Bool

    init(
        id: UUID = UUID(),
        photoId: Int,
        imageUrl: URL,
        latitude: Double,
        longitude: Double,
        createdAt: Date,
        fileName: String,
        tags: [String],
        isSensitive: Bool
    ) {
        self.id = id
        self.photoId = photoId
        self.imageUrl = imageUrl
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.fileName = fileName
        self.tags = tags
        self.isSensitive = isSensitive
    }
}
