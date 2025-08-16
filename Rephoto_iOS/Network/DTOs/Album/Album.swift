
// DTOs/Album/Album.swift
import Foundation

public struct Album: Codable, Equatable {
    public let user: User
    public let tag: Tag
}
