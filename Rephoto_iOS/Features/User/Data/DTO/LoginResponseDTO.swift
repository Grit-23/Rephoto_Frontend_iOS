//
//  LoginResponseDTO.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

struct LoginResponseDTO: Codable {
    let accessToken: String
    let refreshToken: String
}
