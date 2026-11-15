//
//  UserRequestDTO.swift
//  UserDomain
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation

struct JoinRequestDTO: Encodable, Sendable {
    let loginId: String
    let password: String
    let username: String
}

struct LoginRequestDTO: Encodable, Sendable {
    let loginId: String
    let password: String
}

struct UpdateUserRequestDTO: Encodable, Sendable {
    let username: String
    let password: String
}
