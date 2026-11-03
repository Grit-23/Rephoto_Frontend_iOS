//
//  PhotoDTO.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import PhotoDomainInterface
import RephotoFoundation

struct PhotoResponseDTO: Decodable {
    let photoId: Int
    let imageUrl: String
    let latitude: Double
    let longitude: Double
    let createdAt: String
    let fileName: String
    let tags: [String]
    let isSensitive: Bool

    func toDomain() throws -> Photo {
        guard let url = URL(string: imageUrl) else {
            throw RepositoryError.invalidData(detail: "imageUrl 파싱 실패: \(imageUrl)")
        }
        // 서버가 `Z`를 붙인 ISO 8601로 내려주므로 Foundation의 `serverISO`와는 형식이 다르다.
        // `ISO8601DateFormatter`는 Sendable이 아니라 static으로 공유할 수 없어 값 타입 포맷 스타일을 쓴다.
        guard let date = try? Date(createdAt, strategy: .iso8601) else {
            throw RepositoryError.invalidData(detail: "createdAt 파싱 실패: \(createdAt)")
        }

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

struct PhotoMetadataDTO: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let imageUrl: String
    let createdAt: String
    let fileName: String
}

struct S3UploadResponseDTO: Decodable {
    let imageUrl: String
}

struct PhotoBatchRequestDTO: Encodable, Sendable {
    let photos: [PhotoMetadataDTO]
}
