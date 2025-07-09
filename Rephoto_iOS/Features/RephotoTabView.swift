//
//  RephotoTabView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct RephotoTabView: View {
    @State var tabcase : TabCase = .home
    @State var searchPresented : Bool = false
    @State private var searchText: String = ""
    
    var body : some View {
            TabView(selection: $tabcase) {
                Tab(
                    value: .home,
                    content: {tabView(tab: .home)},
                    label: {tabLabel(.home)}
                )
                
                Tab(
                    value: .map,
                    content: {tabView(tab: .map)},
                    label: {tabLabel(.map)}
                )
                
                Tab(value: .search, role: .search) {
                    tabView(tab: .search)
                }
            }
            .searchable(text: $searchText, isPresented: $searchPresented, prompt: "사진을 검색해보세요!")
            .searchToolbarBehavior(.minimize)
            .tint(.color3)
            .tabBarMinimizeBehavior(.onScrollDown)
            .onChange(of: tabcase) {
                searchPresented = (tabcase == .search)
            }
    }
    
    private func tabLabel(_ tab: TabCase) -> some View {
        VStack{
            tab.icon
                .renderingMode(.template)
            Text(tab.rawValue)
        }
    }
    
    @ViewBuilder
    private func tabView(tab: TabCase) -> some View {
        Group {
            switch tab {
            case .home:
                NavigationStack{
                    HomeView()
                }
            case .map:
                NavigationStack{
                    MapView()
                }
            case .search:
                NavigationStack{
                    SearchView()
                }
            }
        }
    }
}

#Preview {
    RephotoTabView()
}
