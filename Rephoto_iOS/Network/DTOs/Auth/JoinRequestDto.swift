
// DTOs/Auth/JoinRequestDto.swift
import Foundation

public struct JoinRequestDto: Codable {
    public let loginId: String
    public let password: String
    public let username: String
}
