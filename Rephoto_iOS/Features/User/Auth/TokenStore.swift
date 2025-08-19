//
//  TokenStore.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/18/25.
//

import Foundation

struct TokenPair: Codable {
    let accessToken: String
    let refreshToken: String
}

final class TokenStore {
    static let shared = TokenStore()
    private let accessKey = "accessToken"
    private let refreshKey = "refreshToken"

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: accessKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: accessKey) }
    }

    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: refreshKey) }
    }

    func save(_ pair: TokenPair) {
        accessToken = pair.accessToken
        refreshToken = pair.refreshToken
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }

    var hasTokens: Bool { accessToken != nil && refreshToken != nil }
}
