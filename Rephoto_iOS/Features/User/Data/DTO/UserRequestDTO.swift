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
