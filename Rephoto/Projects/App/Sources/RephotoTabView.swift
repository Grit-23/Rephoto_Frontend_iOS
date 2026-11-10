//
//  RephotoTabView.swift
//  Rephoto
//
//  Created by Doyeon Kim on 11/10/26.
//

import SwiftUI
import DesignSystem
import HomeFeature
import HomeFeatureInterface
import SearchFeature

/// 홈 · 검색 탭. 컨테이너는 루트(`RephotoApp`)에서만 읽고, 여기는 조립된 객체를 init으로 받는다.
/// 세션 `environment` 연결과 계정 시트 내용은 User 이관 때 붙는다.
struct RephotoTabView: View {
    private enum AppTab {
        case home, search
    }

    let homeProvider: any HomeUseCaseProviderProtocol
    let searchProvider: any SearchUseCaseProviderProtocol
    let photoDetail: any PhotoDetailBuilding
    let errorHandler: ErrorHandler
    let onProfileTap: () -> Void
    @State private var selectedTab: AppTab = .home
    @State private var searchQuery = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("홈", systemImage: "house", value: .home) {
                HomeView(provider: homeProvider, errorHandler: errorHandler, onProfileTap: onProfileTap)
            }
            Tab("검색", systemImage: "magnifyingglass", value: .search, role: .search) {
                SearchView(provider: searchProvider, photoDetail: photoDetail, query: searchQuery)
            }
        }
        .searchable(text: $searchQuery, prompt: "사진을 검색해보세요!")
        .searchFocused($isSearchFocused)
        .tint(.mainGreen)
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    /// 이미 선택된 검색 탭을 다시 누르면 검색 필드에 포커스를 준다
    private var tabSelection: Binding<AppTab> {
        Binding {
            selectedTab
        } set: { tab in
            if tab == .search, selectedTab == .search {
                isSearchFocused = true
            }
            selectedTab = tab
        }
    }
}
