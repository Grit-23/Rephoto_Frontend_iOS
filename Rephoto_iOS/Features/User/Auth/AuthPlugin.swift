//
//  AuthPlugin.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/18/25.
//

import Moya
import Foundation

final class AuthPlugin: PluginType {
    private let tokenStore: TokenStore

    init(tokenStore: TokenStore = .shared) {
        self.tokenStore = tokenStore
    }

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var req = request

        // 로그인/리프레시 등 "토큰 불필요" 엔드포인트는 제외
        if let api = target as? UserAPITarget {
            switch api {
            case .login, .refreshToken:
                return req
            default:
                break
            }
        }

        if let token = tokenStore.accessToken, !token.isEmpty {
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }
}
