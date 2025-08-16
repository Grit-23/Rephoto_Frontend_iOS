
// DTOs/Photos/PhotoResponseDto.swift
import Foundation

public struct PhotoResponseDto: Codable {
    public let photoId: Int
    public let imageUrl: String
    public let latitude: Double
    public let longitude: Double
    /// ISO 8601 string
    public let createdAt: String
    public let fileName: String
    public let tags: [String]
    public let isPrivate: Bool

    private enum CodingKeys: String, CodingKey {
        case photoId, imageUrl, latitude, longitude, createdAt, fileName, tags
        case isPrivate = "private"
    }
}
// DTO -> Domain 변환 Extension
extension PhotoResponseDto {
    func toHomeModel() -> HomeModel {
        return HomeModel(
            photoId: photoId,
            imageUrl: URL(string: imageUrl)!,
            latitude: latitude,
            longitude: longitude,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            fileName: fileName,
            tags: tags,
            isSensitive: isPrivate // 서버의 private 필드를 isSensitive로 매핑
        )
    }
}
