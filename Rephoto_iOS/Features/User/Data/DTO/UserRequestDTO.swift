//
//  UserRequestDTO.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation

struct JoinRequestDTO: Encodable {
    let loginId: String
    let password: String
    let username: String
}

struct LoginRequestDTO: Encodable {
    let loginId: String
    let password: String
}

struct UpdateUserRequestDTO: Encodable {
    let username: String
    let password: String
}

struct RefreshTokenRequestDTO: Encodable {
    let refreshToken: String

    // 서버가 바디 필드명으로 "Authorization"을 기대함
    enum CodingKeys: String, CodingKey {
        case refreshToken = "Authorization"
    }
}
