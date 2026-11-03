//
//  Photo.swift
//  PhotoDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

public struct Photo: Identifiable, Hashable, Sendable {
    public var id: Int { photoId }
    public let photoId: Int
    public let imageUrl: URL
    public let latitude: Double
    public let longitude: Double
    public let createdAt: Date
    public let fileName: String
    public let tags: [String]
    public let isSensitive: Bool

    public init(
        photoId: Int,
        imageUrl: URL,
        latitude: Double,
        longitude: Double,
        createdAt: Date,
        fileName: String,
        tags: [String],
        isSensitive: Bool
    ) {
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
