//
//  RephotoTabView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import PhotosUI
import Factory

struct RephotoTabView: View {
    @Injected(\.sessionStore) private var session
    @Injected(\.homeUseCaseProvider) private var homeProvider
    @Injected(\.searchUseCaseProvider) private var searchProvider

    var body : some View {
        TabView{
            Tab("홈", systemImage: "house") {
                HomeView(provider: homeProvider)
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                SearchView(provider: searchProvider)
            }
        }
        .tint(.green)
        .tabBarMinimizeBehavior(.onScrollDown)
        // 하위 탭(프로필/로그아웃 UI 등)이 @Environment(SessionStore.self)로 세션에 접근
        .environment(session)
    }
}

#Preview {
    RephotoTabView()
}
