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
    @Injected(\.homeUseCaseProvider) private var homeProvider

    var body : some View {
        TabView{
            Tab("홈", image: "home") {
                HomeView(provider: homeProvider)
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                SearchView()
            }
        }
        .tint(.green)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    RephotoTabView()
}
