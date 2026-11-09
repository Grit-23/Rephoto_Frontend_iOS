//
//  RephotoApp.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//

import SwiftUI
import Factory
import DesignSystem
import HomeFeature

/// Tuist 전환 중 임시 진입점. 로그인 · 탭 · 계정 시트는 Search · User 이관 때 붙는다.
///
/// Home은 프로필 버튼 액션만 받고, 계정 시트 표시는 App이 소유한다.
/// 전역 에러 Alert은 루트에 한 번만 붙이며, ViewModel이 쓰는 `ErrorHandler`와 같은 인스턴스다.
@main
struct RephotoApp: App {
    private let provider = Container.shared.homeUseCaseProvider()
    private let errorHandler = Container.shared.errorHandler()
    @State private var isPresentingAccount = false

    var body: some Scene {
        WindowGroup {
            HomeView(provider: provider, errorHandler: errorHandler) {
                isPresentingAccount = true
            }
            .sheet(isPresented: $isPresentingAccount) {
                ContentUnavailableView("내 정보", systemImage: "person.fill")
                    .presentationDetents([.medium])
            }
            .globalErrorAlert(errorHandler)
        }
    }
}
