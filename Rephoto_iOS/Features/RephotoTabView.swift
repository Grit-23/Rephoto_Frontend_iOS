//
//  RephotoTabView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct RephotoTabView: View {
    
    var body : some View {
        TabView{
            Tab("홈", image: "home") {
                NavigationStack {
                    HomeView()
                }
            }
            Tab("지도", image: "map") {
                NavigationStack {
                    MapView()
                }
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                NavigationStack {
                    SearchView()
                        .navigationTitle("검색")
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.color6)
    }
}

#Preview {
    RephotoTabView()
}
