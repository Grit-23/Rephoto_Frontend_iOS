//
//  HomeSheetView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct HomeSheetView: View {
    @Binding var sheetDetent: PresentationDetent
    
    // MARK: - HomeSheetView 설정, 사진 업로드, 사진 공유, 쓰래기 통, 도움, 로그아웃 가능
    
    var body: some View {
        NavigationStack{
            VStack{
                userInfo
                Divider()
                
                components
                
                Spacer()
            }
            .padding(.all)
        }
    }
    
    var userInfo: some View {
        HStack{
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 52, height: 52)
            
            Text("UserName")
                .font(.largeTitle)
            
            Spacer()
            
            NavigationLink {
                // SettingsView 호출할 때 sheetDetent large로 변환 -> SettingsView내부에서 dismiss시 medium으로 반환
                SettingsView(sheetDetent: $sheetDetent)
                    .onAppear {
                        sheetDetent = .large
                    }
            } label: {
                Image(systemName: "gearshape")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.black)
            }
        }
        .padding(.top)
    }
    
    var components: some View {
        VStack{
            ForEach(HomeSheetCase.allCases, id: \.rawValue){ component in
                NavigationLink {
                    //위에 SettingsView참고해서 추후 개발
                    component.destinationView(sheetDetent: $sheetDetent)
                        .onAppear {
                            sheetDetent = component.detent
                        }
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
