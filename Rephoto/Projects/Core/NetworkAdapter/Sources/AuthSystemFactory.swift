//
//  AuthSystemFactory.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

/// 인증 관련 의존성을 조립해주는 팩토리.
///
/// 이 모듈 안의 부품(`KeychainTokenStore` · `TokenRefreshServiceImpl` · `NetworkClient`)만 묶는다.
/// Feature · Domain 구현의 조립은 App의 `AppContainer`가 한다.
public enum AuthSystemFactory {

    /// 실제 앱에서 사용할 NetworkClient를 생성
    public static func makeNetworkClient(
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
