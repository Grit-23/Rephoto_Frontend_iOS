//
//  ContentView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/3/25.
//

import SwiftUI
import Factory

struct ContentView: View {
    @Injected(\.sessionStore) private var session

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
    ContentView()
}
#endif
