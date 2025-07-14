//
//  RephotoTabView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct RephotoTabView: View {
    @State private var searchText: String = ""
    
    var body : some View {
        TabView{
            Tab("Home", image: "home") {
                HomeView()
            }
            Tab("Map", image: "map") {
                MapView()
            }
            Tab(role: .search) {
                NavigationStack {
                    SearchView()
                }
                .searchable(text: $searchText, prompt: "사진을 검색해보세요!")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.color6)
    }
}

#Preview {
    RephotoTabView()
}
