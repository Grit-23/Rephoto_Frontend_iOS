//
//  LoginResponseDTO.swift
//  UserDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

struct LoginResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}
