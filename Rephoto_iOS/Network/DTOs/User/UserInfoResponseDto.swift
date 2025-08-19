
// DTOs/User/UserInfoResponseDto.swift
import Foundation

public struct UserInfoResponseDto: Codable {
    public let userId: Int
    public let loginId: Int
    public let name: String
}
