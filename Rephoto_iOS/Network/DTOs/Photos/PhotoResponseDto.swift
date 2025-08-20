
// DTOs/Photos/PhotoResponseDto.swift
import Foundation

public struct PhotoResponseDto: Codable {
    public let photoId: Int
    public let imageUrl: URL
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let parsedDate = formatter.date(from: createdAt) ?? Date()

        return HomeModel(
            photoId: photoId,
            imageUrl: imageUrl,
            latitude: latitude,
            longitude: longitude,
            createdAt: parsedDate,
            fileName: fileName,
            tags: tags,
            isSensitive: isPrivate
        )
    }
}
