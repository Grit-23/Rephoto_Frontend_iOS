//
//  TokenPair.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

struct TokenPair: Sendable, Codable, Equatable {
    /// actor의 isolation 규칙 무시 → 불변 값이므로 동시에 여러 곳에서 참조 가능
    nonisolated let accessToken: String
    nonisolated let refreshToken: String

    nonisolated init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
