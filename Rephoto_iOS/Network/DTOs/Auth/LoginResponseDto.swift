
// DTOs/Auth/LoginResponseDto.swift
import Foundation

public struct LoginResponseDto: Codable {
    public let accessToken: String
    public let refreshToken: String
}
