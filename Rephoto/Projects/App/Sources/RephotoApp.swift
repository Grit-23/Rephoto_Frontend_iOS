//
//  RephotoApp.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//

import SwiftUI
import Factory
import DesignSystem

/// 컨테이너는 여기서만 읽고 하위 뷰에는 init으로 넘긴다.
/// 전역 에러 Alert은 루트에 한 번만 붙이며, ViewModel이 쓰는 `ErrorHandler`와 같은 인스턴스다.
@main
struct RephotoApp: App {
    private let session = Container.shared.sessionStore()
    private let homeProvider = Container.shared.homeUseCaseProvider()
    private let searchProvider = Container.shared.searchUseCaseProvider()
    private let photoDetail = Container.shared.photoDetailBuilder()
    private let errorHandler = Container.shared.errorHandler()

    var body: some Scene {
        WindowGroup {
            RootView(
                session: session,
                homeProvider: homeProvider,
                searchProvider: searchProvider,
                photoDetail: photoDetail,
                errorHandler: errorHandler
            )
            .globalErrorAlert(errorHandler)
        }
    }
}
