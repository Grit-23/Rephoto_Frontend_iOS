//
//  UserAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/13/25.
//

import Foundation
import Moya
import Alamofire

enum UserAPITarget {
    case join(loginId: String, password: String, username: String)
    case login(loginId: String, password: String)
    case kakaologin(accessToken: String)
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
        case .kakaologin:
            return "/kakao/login"
        case .logout:
            return "/logout"
        case .refreshToken:
            return "/auth/refresh"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .join, .kakaologin, .login, .logout, .refreshToken:
            return .post
        case .updateUser:
            return .put
        case .getUser:
            return .get
        case .deleteUser:
            return .delete
        }
    }
    
    var task: Task {
        switch self {
        case .join(let loginId, let password, let username):
            let parameters: [String: Any] = [
                "loginId": loginId,
                "password": password,
                "username": username
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .login(let loginId, let password):
            let parameters: [String: Any] = [
                "loginId": loginId,
                "password": password
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .kakaologin(let accessToken):
            let parameters: [String: Any] = [
                "accessToken": accessToken
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .updateUser(let username, let password):
            let parameters: [String: Any] = [
                "username": username,
                "password": password
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .getUser, .logout, .deleteUser:
            return .requestPlain
        case .refreshToken(let refreshToken):
            let parameters: [String: Any] = [
                "Authorization": refreshToken
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }
    
    var authorizationType: AuthorizationType? {
        switch self {
        case .logout, .getUser, .deleteUser, .updateUser:
            return .bearer
        case .login, .join, .kakaologin, .refreshToken:
            return .none
        }
    }

    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
}
