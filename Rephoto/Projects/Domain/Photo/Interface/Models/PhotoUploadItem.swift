//
//  PhotoUploadItem.swift
//  PhotoDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

public struct PhotoUploadItem: Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public let imageUrl: URL
    public let createdAt: String
    public let fileName: String

    public init(latitude: Double, longitude: Double, imageUrl: URL, createdAt: String, fileName: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.fileName = fileName
    }
}
