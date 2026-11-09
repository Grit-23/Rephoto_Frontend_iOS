//
//  HomeFeatureExampleApp.swift
//  HomeFeatureExample
//
//  Created by Doyeon Kim on 11/6/26.
//

import SwiftUI
import DesignSystem
import HomeFeature

/// HomeFeature만 단독으로 띄워 확인하는 앱. 서버 대신 PreviewSupport의 메모리 Repository를 쓴다.
/// 목록 · 업로드 · 상세(태그 · 설명 · 지도) · 민감 사진 Face ID · 프로필 액션을 여기서 확인한다.
@main
struct HomeFeatureExampleApp: App {
    @State private var errorHandler = ErrorHandler()
    @State private var isShowingProfileAlert = false
    private let provider = ExampleHomeProvider()

    var body: some Scene {
        WindowGroup {
            HomeView(provider: provider, errorHandler: errorHandler) {
                isShowingProfileAlert = true
            }
            .alert("프로필 버튼", isPresented: $isShowingProfileAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("App에서는 계정 시트가 열린다")
            }
            .globalErrorAlert(errorHandler)
        }
    }
}
