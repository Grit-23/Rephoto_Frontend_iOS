
// DTOs/Map/MapRequestDto.swift
import Foundation

public struct MapRequestDto: Codable {
    public let minLat: Double
    public let maxLat: Double
    public let minLng: Double
    public let maxLng: Double
    public let zoomLevel: Int // API shows int32
}
