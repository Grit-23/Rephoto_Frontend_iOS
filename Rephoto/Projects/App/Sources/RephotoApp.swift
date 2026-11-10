//
//  RephotoApp.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//

import SwiftUI
import Factory
import DesignSystem

/// Tuist 전환 중 임시 진입점. 로그인 분기 · 세션 · 계정 시트 내용은 User 이관 때 붙는다.
///
/// 컨테이너는 여기서만 읽고 탭 뷰에는 init으로 넘긴다. 계정 시트 표시는 App이 소유한다.
/// 전역 에러 Alert은 루트에 한 번만 붙이며, ViewModel이 쓰는 `ErrorHandler`와 같은 인스턴스다.
@main
struct RephotoApp: App {
    private let homeProvider = Container.shared.homeUseCaseProvider()
    private let searchProvider = Container.shared.searchUseCaseProvider()
    private let photoDetail = Container.shared.photoDetailBuilder()
    private let errorHandler = Container.shared.errorHandler()
    @State private var isPresentingAccount = false

    var body: some Scene {
        WindowGroup {
            RephotoTabView(
                homeProvider: homeProvider,
                searchProvider: searchProvider,
                photoDetail: photoDetail,
                errorHandler: errorHandler
            ) {
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
