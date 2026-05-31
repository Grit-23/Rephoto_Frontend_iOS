//
//  AuthSystemFactory.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

/// 인증 관련 의존성을 조립해주는 팩토리
enum AuthSystemFactory {

    /// 실제 앱에서 사용할 NetworkClient를 생성
    static func makeNetworkClient(
        baseURL: URL,
        session: URLSession = .shared,
        tokenStore: TokenStore? = nil
    ) -> NetworkClient {
        let store = tokenStore ?? KeychainTokenStore()
        let refreshService = TokenRefreshServiceImpl(baseURL: baseURL, session: session)

        return NetworkClient(
            session: session,
            tokenStore: store,
            refreshService: refreshService
        )
    }
}
