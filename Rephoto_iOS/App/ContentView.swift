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
    @Injected(\.errorHandler) private var errorHandler

    var body: some View {
        Group {
            if session.isLoggedIn {
                RephotoTabView()
            } else {
                LoginView(session: session)
            }
        }
        .task { await session.restore() }
        // 전역 에러 Alert은 앱 루트에 한 번만 부착한다.
        // ErrorHandler는 ViewModel이 생성자로 주입받으므로 환경에는 넣지 않는다 —
        // 읽는 뷰가 없는 주입은 죽은 코드다
        .globalErrorAlert(errorHandler)
    }
}

#if DEBUG
#Preview {
    ContentView()
}
#endif
