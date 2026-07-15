//
//  UserAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/13/25.
//

import Foundation

enum UserAPITarget {
    case join(loginId: String, password: String, username: String)
    case login(loginId: String, password: String)
    case updateUser(username: String, password: String)
    case getUser
    case deleteUser
    case logout
    case refreshToken(refreshToken: String)
}

extension UserAPITarget: APITargetType {
    var path: String {
        switch self {
        case .join:
            return "/join"
        case .login:
            return "/login"
        case .getUser, .updateUser, .deleteUser:
            return "/users"
        case .logout:
            return "/logout"
        case .refreshToken:
            return "/auth/refresh"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .join, .login, .logout, .refreshToken:
            return .post
        case .updateUser:
            return .put
        case .getUser:
            return .get
        case .deleteUser:
            return .delete
        }
    }

    var task: RequestTask {
        switch self {
        case .join(let loginId, let password, let username):
            return .jsonEncodable(JoinRequestDTO(loginId: loginId, password: password, username: username))
        case .login(let loginId, let password):
            return .jsonEncodable(LoginRequestDTO(loginId: loginId, password: password))
        case .updateUser(let username, let password):
            return .jsonEncodable(UpdateUserRequestDTO(username: username, password: password))
        case .getUser, .logout, .deleteUser:
            return .plain
        case .refreshToken(let refreshToken):
            return .jsonEncodable(RefreshTokenRequestDTO(refreshToken: refreshToken))
        }
    }

}
