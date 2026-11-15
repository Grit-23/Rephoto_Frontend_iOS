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
import UserFeature

/// 홈 · 검색 탭. 컨테이너는 루트(`RephotoApp`)에서만 읽고, 여기는 조립된 객체를 init으로 받는다.
/// 계정 시트 표시는 App이 소유한다. 로그아웃하면 이 뷰가 사라지므로 시트 표시 상태도 함께 사라진다.
struct RephotoTabView: View {
    private enum AppTab {
        case home, search
    }

    let session: SessionStore
    let homeProvider: any HomeUseCaseProviderProtocol
    let searchProvider: any SearchUseCaseProviderProtocol
    let photoDetail: any PhotoDetailBuilding
    let errorHandler: ErrorHandler
    @State private var isPresentingAccount = false
    @State private var selectedTab: AppTab = .home
    @State private var searchQuery = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("홈", systemImage: "house", value: .home) {
                HomeView(provider: homeProvider, errorHandler: errorHandler) {
                    isPresentingAccount = true
                }
            }
            Tab("검색", systemImage: "magnifyingglass", value: .search, role: .search) {
                SearchView(provider: searchProvider, photoDetail: photoDetail, query: searchQuery)
            }
        }
        .searchable(text: $searchQuery, prompt: "사진을 검색해보세요!")
        .searchFocused($isSearchFocused)
        .tint(.mainGreen)
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(isPresented: $isPresentingAccount) {
            AccountSheetView(session: session)
        }
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
