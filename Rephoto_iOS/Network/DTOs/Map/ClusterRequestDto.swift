
// DTOs/Map/ClusterRequestDto.swift
import Foundation

public struct ClusterRequestDto: Codable {
    public let cellLat: Double
    public let cellLng: Double
    public let zoomLevel: Int // API shows int32
}
