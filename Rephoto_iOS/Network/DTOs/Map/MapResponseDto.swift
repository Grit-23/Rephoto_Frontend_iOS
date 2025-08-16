
// DTOs/Map/MapResponseDto.swift
import Foundation

public struct MapResponseDto: Codable, Equatable {
    public let cellLat: Double
    public let cellLng: Double
    public let thumbnailUrl: String
    public let photoCount: Int
}
