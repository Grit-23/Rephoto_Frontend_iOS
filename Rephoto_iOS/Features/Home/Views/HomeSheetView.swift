//
//  HomeSheetView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct HomeSheetView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @Binding var sheetDetent: PresentationDetent
    
    // MARK: - HomeSheetView 설정, 쓰래기 통, 도움, 로그아웃 가능
    var body: some View {
        NavigationStack{
            VStack{
                userInfo
                Divider()
                components
                Spacer()
            }
            .padding()
        }
    }
    
    var userInfo: some View {
        HStack{
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 52, height: 52)
            
            Text("\(loginViewModel.name)")
                .font(.title2)
                .bold()
            
            Spacer()
            
            NavigationLink {
                SettingsView(sheetDetent: $sheetDetent)
                    .task {
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
        VStack(spacing: 12){
            NavigationLink {
                
            } label: {
                HStack(spacing: 20){
                    Image(systemName: "trash")
                    Text("삭제된 사진")
                        .font(.title3)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .tint(.black)
                .padding(.top)
            }
            
            NavigationLink {
                
            } label: {
                HStack(spacing: 20){
                    Image(systemName: "questionmark.circle")
                    Text("리포토에게 문의하기")
                        .font(.title3)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .tint(.black)
                .padding(.top)
            }
            
            Button {
                loginViewModel.logout()
            } label: {
                HStack(spacing: 20){
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("로그아웃")
                        .font(.title3)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .tint(.red)
                .padding(.top)
            }
        }
    }
    
    private func logout() {
        // 1. 토큰 삭제
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        
        // 2. 서버 로그아웃 API 호출 (선택)
        // provider.request(.logout(userId: ...)) { ... }
        
        // 3. 로그인 화면으로 이동
        loginViewModel.isLoggedIn = false
    }
}

#Preview {
    HomeSheetView(sheetDetent: .constant(.medium))
        .environmentObject(LoginViewModel()) // EnvironmentObject 주입
}
