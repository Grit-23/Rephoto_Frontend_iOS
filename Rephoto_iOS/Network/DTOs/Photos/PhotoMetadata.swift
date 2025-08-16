
// DTOs/Photos/PhotoMetadata.swift
import Foundation

public struct PhotoMetadata: Codable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public let imageUrl: String
    /// ISO 8601 string (e.g. "2025-07-20T15:00:00")
    public let createdAt: String
    public let fileName: String
}
