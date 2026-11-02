//
//  TokenPair.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

public struct TokenPair: Sendable, Equatable, Codable {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
