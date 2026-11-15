//
//  UserFeatureExampleApp.swift
//  UserFeatureExample
//
//  Created by Doyeon Kim on 11/15/26.
//

import SwiftUI
import PreviewSupport
import UserFeature

/// UserFeature만 단독으로 띄워 확인하는 앱. 서버 대신 PreviewSupport의 메모리 Repository를 쓴다.
/// 로그인 → 계정 시트 → 로그아웃, 갱신 실패 시 로그인 화면 복귀를 여기서 확인한다.
/// 실행 인자 `-loggedIn`을 주면 토큰이 저장된 상태로 시작해 세션 복원 경로를 탄다.
@main
struct UserFeatureExampleApp: App {
    private let provider: ExampleUserProvider
    @State private var session: SessionStore

    init() {
        let provider = ExampleUserProvider(
            isLoggedIn: ProcessInfo.processInfo.arguments.contains("-loggedIn")
        )
        self.provider = provider
        self._session = State(initialValue: SessionStore(provider: provider))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    SignedInView(session: session) {
                        provider.repository.failRefresh()
                    }
                } else {
                    LoginView(session: session)
                }
            }
            .task { await session.restore() }
        }
    }
}

private struct SignedInView: View {
    let session: SessionStore
    let onFailRefresh: () -> Void
    @State private var isPresentingAccount = false

    var body: some View {
        VStack(spacing: 20) {
            Text("\(session.name) 님으로 로그인됨")
            Button("내 정보") { isPresentingAccount = true }
            Button("토큰 갱신 실패 일으키기", role: .destructive, action: onFailRefresh)
        }
        .sheet(isPresented: $isPresentingAccount) {
            AccountSheetView(session: session)
        }
    }
}
