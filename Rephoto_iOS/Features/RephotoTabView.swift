//
//  RephotoTabView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct RephotoTabView: View {
    @State var tabcase : TabCase = .home
    @State private var searchText: String = ""
    
    var body : some View {
        NavigationStack{
            TabView(selection: $tabcase, content: {
                ForEach(TabCase.allCases, id: \.rawValue){ tab in
                    Tab(
                    value: tab,
                        content: {
                            tabView(tab: tab)
                                .tag(tab)
                        },
                        label: {
                            tabLabel(tab)
                        })
                }
            })
            .tint(.color3)
            .tabBarMinimizeBehavior(.onScrollDown)
            .searchable(text: $searchText)
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
                HomeView()
            case .map:
                MapView()
            case .search:
                SearchView()
            }
        }
    }
}

#Preview {
    RephotoTabView()
}
