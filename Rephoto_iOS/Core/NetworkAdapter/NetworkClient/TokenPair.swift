//
//  TokenPair.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

struct TokenPair: Sendable, Codable, Equatable {
    let accessToken: String
    let refreshToken: String
}
