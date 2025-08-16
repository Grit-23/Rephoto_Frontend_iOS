
// DTOs/Search/SearchResponseDto.swift
import Foundation

public struct SearchResponseDto: Codable {
    public let query: String
    public let searchResults: [SearchResults]
}
