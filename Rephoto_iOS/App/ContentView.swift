//
//  ContentView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var session: SessionStore

    init(userProvider: UserUseCaseProviderProtocol) {
        self._session = State(initialValue: SessionStore(provider: userProvider))
    }

    var body: some View {
        Group {
            if session.isLoggedIn {
                RephotoTabView()
            } else {
                LoginView(session: session)
            }
        }
        .task { await session.restore() }
    }
}

#if DEBUG
#Preview {
    ContentView(userProvider: MockUserUseCaseProvider())
}
#endif
