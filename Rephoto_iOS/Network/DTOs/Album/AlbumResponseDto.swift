
// DTOs/Album/AlbumResponseDto.swift
import Foundation

public struct AlbumResponseDto: Codable, Identifiable {
    public var userId: Int
    public var tagId: Int
    public var tagName: String
    public var id: Int { tagId }
}
