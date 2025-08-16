
// DTOs/Album/AlbumResponseDto.swift
import Foundation

public struct AlbumResponseDto: Codable, Equatable {
    public let userId: Int
    public let tagId: Int
    public let tagName: String
}
