//
//  ContentView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var loginVM: LoginViewModel

    init(userProvider: UserUseCaseProviderProtocol) {
        self._loginVM = State(initialValue: LoginViewModel(provider: userProvider))
    }

    var body: some View {
        Group {
            #if DEBUG
            if true {
                RephotoTabView()
            }
            #else
            if loginVM.isLoggedIn {
                RephotoTabView()
            } else {
                LoginView(loginVM: loginVM)
            }
            #endif
        }
    }
}

#if DEBUG
#Preview {
    ContentView(userProvider: MockUserUseCaseProvider())
}
#endif
