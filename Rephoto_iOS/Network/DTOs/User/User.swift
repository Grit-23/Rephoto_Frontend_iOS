
// DTOs/User/User.swift
import Foundation

public struct User: Codable, Equatable {
    public let userId: Int
    public let username: String
    public let loginId: String
    public let password: String
    public let loggedIn: Bool
}
