//
//  PhotoDTO.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

struct PhotoResponseDTO: Decodable {
    let photoId: Int
    let imageUrl: String
    let latitude: Double
    let longitude: Double
    let createdAt: String
    let fileName: String
    let tags: [String]
    let isSensitive: Bool

    func toDomain() -> Photo {
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: createdAt) ?? Date()
        let url = URL(string: imageUrl) ?? URL(string: "https://placeholder.com")!

        return Photo(
            photoId: photoId,
            imageUrl: url,
            latitude: latitude,
            longitude: longitude,
            createdAt: date,
            fileName: fileName,
            tags: tags,
            isSensitive: isSensitive
        )
    }
}

struct PhotoMetadataDTO: Codable {
    let latitude: Double
    let longitude: Double
    let imageUrl: String
    let createdAt: String
    let fileName: String
}

struct S3UploadResponseDTO: Decodable {
    let imageUrl: String
}

struct PhotoBatchRequestDTO: Encodable {
    let photos: [PhotoMetadataDTO]
}
