//
//  RephotoTabView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import PhotosUI

struct RephotoTabView: View {
    var body : some View {
        TabView{
            Tab("홈", image: "home") {
                HomeView()
            }
            Tab("지도", image: "map") {
                NavigationStack {
                    MapView()
                }
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                SearchView()
                    .navigationTitle("검색")
            }
        }
        .tint(.green)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    RephotoTabView()
}
