//
//  Rephoto_iOSApp.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/3/25.
//

import SwiftUI
import SwiftData

@main
struct Rephoto_iOSApp: App {
    
    @State private var container: DIContainer
    @State private var appState: AppState = .main
    private let sharedModelContainer: ModelContainer
    
    // MARK: - AppState
    
    private enum AppState {
        case splash
        
        case login
        
        case signUp(verificationToken: String)
        
        case main
    }
    
    init() {
        sharedModelContainer = Self.makeModelContainer()
        _container = State(
            initialValue: DIContainer.configured(
                modelContext: sharedModelContainer.mainContext
            )
        )
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            rootView
                .environment(\.di, container)
                .environment(\.appFlow, appFlow)
                .modelContainer(sharedModelContainer)
        }
    }
}


extension Rephoto_iOSApp {
    @ViewBuilder
    private var rootView: some View {
        switch appState {
        case .splash:
            EmptyView()
        case .login:
            LoginView()
        case .signUp(let verificationToken):
            EmptyView()
        case .main:
            RephotoTabView()
        }
    }
    
    private func transition(to state: AppState) {
        withAnimation {
            appState = state
        }
    }
    
    /// 세션 만료 시 캐시 초기화 후 로그인 화면으로 전환합니다.
    private func handleAuthSessionExpired() {
        Task {
//            try? await container.resolve(NetworkClient.self).logout()
        }
        container.resetCache()
        transition(to: .login)
    }
    
    private var appFlow: AppFlow {
        AppFlow(
            showLogin: { transition(to: .login) },
            showMain: { transition(to: .main) },
            showSignUp: { verificationToken in
                transition(to: .signUp(verificationToken: verificationToken))
            },
            logout: { handleAuthSessionExpired() }
        )
    }
    
    /// SwiftData ModelContainer를 생성
    ///
    /// - Returns: 생성된 ModelContainer
    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            PhotoItem.self
        ])
        
        do {
            let memoryConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            return try ModelContainer(
                for: schema,
                configurations: [memoryConfiguration]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
}
