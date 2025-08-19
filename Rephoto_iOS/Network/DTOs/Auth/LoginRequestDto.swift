
// DTOs/Auth/LoginRequestDto.swift
import Foundation

public struct LoginRequestDto: Codable {
    public let loginId: String
    public let password: String
}
