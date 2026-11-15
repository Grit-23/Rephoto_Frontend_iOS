//
//  UserInfo.swift
//  UserDomainInterface
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

public struct UserInfo: Equatable, Sendable {
    public let userId: Int
    public let loginId: Int
    public let name: String

    public init(userId: Int, loginId: Int, name: String) {
        self.userId = userId
        self.loginId = loginId
        self.name = name
    }
}
