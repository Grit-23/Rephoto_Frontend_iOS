//
//  UserInfoResponseDTO.swift
//  UserDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import UserDomainInterface

struct UserInfoResponseDTO: Decodable {
    let userId: Int
    let loginId: Int
    let name: String

    func toDomain() -> UserInfo {
        UserInfo(userId: userId, loginId: loginId, name: name)
    }
}
