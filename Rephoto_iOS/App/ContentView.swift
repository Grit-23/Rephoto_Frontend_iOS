//
//  ContentView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/3/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    var body: some View {
        Group {
            if loginViewModel.isLoggedIn {
                RephotoTabView()
            } else {
                LoginView(onLoginSuccess: {
                    loginViewModel.isLoggedIn = true
                })
            }
        }
        .task {
            if let token = UserDefaults.standard.string(forKey: "accessToken"),
               !token.isEmpty {
                loginViewModel.isLoggedIn = true
            }
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(LoginViewModel())
}
