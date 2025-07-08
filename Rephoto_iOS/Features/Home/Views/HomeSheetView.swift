//
//  HomeSheetView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct HomeSheetView: View {
    
    @Binding var sheetDetent: PresentationDetent
    
    var body: some View {
        NavigationStack{
            VStack{
                UserInfo
                Divider()
                
                Components
                
                Spacer()
            }
            .padding(.all)
        }
    }
    
    var UserInfo: some View {
        HStack{
            Image(systemName: "circle")
                .resizable()
                .frame(width: 52, height: 52)
            
            Text("UserName")
                .font(.largeTitle)
            
            Spacer()
            
            NavigationLink {
                SettingsView()
                    .onAppear{sheetDetent = .large}
                    .onDisappear{sheetDetent = .medium}
            } label: {
                Image(systemName: "gearshape")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.black)
            }
        }
        .padding(.top)
    }
    
    var Components: some View {
        VStack{
            ForEach(HomeSheetCase.allCases, id: \.rawValue){ component in
                NavigationLink {
                    
                } label: {
                    HStack(spacing: 20){
                        component.icon
                        Text(component.rawValue)
                            .font(.title3)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(component.color)
                    .padding(.top)
                }
            }
        }
    }
}

#Preview {
    HomeSheetView(sheetDetent: .constant(.medium))
}
