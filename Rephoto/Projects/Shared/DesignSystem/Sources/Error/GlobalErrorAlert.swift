//
//  GlobalErrorAlert.swift
//  DesignSystem
//
//  Created by Doyeon Kim on 8/28/26.
//

import SwiftUI
import RephotoFoundation

/// ``ErrorHandler``가 수집한 에러를 Alert으로 띄우는 모디파이어.
///
/// 앱 루트에 한 번만 붙이면 모든 화면의 전역 에러가 여기로 모인다.
///
/// `ErrorHandler`의 상태는 이 모디파이어의 `body`에서만 읽는다 — View 확장 함수 안에서 읽으면
/// 관찰 의존성이 호출한 루트 뷰에 걸려, 에러가 뜨고 닫힐 때마다 루트 전체가 재평가된다.
private struct GlobalErrorAlert: ViewModifier {
    @Bindable var errorHandler: ErrorHandler

    func body(content: Content) -> some View {
        content.alert(
            Text(errorHandler.currentError?.alertTitle ?? "오류"),
            // 클로저 바인딩 대신 ErrorHandler의 프로퍼티로 KeyPath 바인딩을 만든다
            isPresented: $errorHandler.isPresentingError,
            presenting: errorHandler.currentError
        ) { _ in
            if errorHandler.showRetry, let retry = errorHandler.retryAction {
                Button("다시 시도") {
                    errorHandler.clear()
                    Task { await retry() }
                }
            }
            Button("확인", role: .cancel) {
                errorHandler.clear()
            }
        } message: { error in
            Text(error.userMessage)
        }
    }
}

extension View {
    /// 전역 에러 Alert을 부착한다. 앱 루트 뷰에서 한 번만 호출한다.
    public func globalErrorAlert(_ errorHandler: ErrorHandler) -> some View {
        modifier(GlobalErrorAlert(errorHandler: errorHandler))
    }
}
