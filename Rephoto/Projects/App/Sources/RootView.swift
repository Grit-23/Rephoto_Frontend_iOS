//
//  RootView.swift
//  Rephoto
//
//  Created by Doyeon Kim on 11/15/26.
//

import SwiftUI
import DesignSystem
import HomeFeature
import HomeFeatureInterface
import SearchFeature
import UserFeature

/// 세션에 따라 로그인 화면과 탭 화면을 가른다. 앱 시작 시 저장된 토큰으로 세션을 복원한다.
struct RootView: View {
    let session: SessionStore
    let homeProvider: any HomeUseCaseProviderProtocol
    let searchProvider: any SearchUseCaseProviderProtocol
    let photoDetail: any PhotoDetailBuilding
    let errorHandler: ErrorHandler

    var body: some View {
        Group {
            if session.isLoggedIn {
                RephotoTabView(
                    session: session,
                    homeProvider: homeProvider,
                    searchProvider: searchProvider,
                    photoDetail: photoDetail,
                    errorHandler: errorHandler
                )
            } else {
                LoginView(session: session)
            }
        }
        .task { await session.restore() }
    }
}
