//
//  GlobalErrorAlert.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import SwiftUI

/// ``ErrorHandler``가 수집한 에러를 Alert으로 띄우는 모디파이어.
///
/// 앱 루트에 한 번만 붙이면 모든 화면의 전역 에러가 여기로 모인다.
private struct GlobalErrorAlert: ViewModifier {
    @Bindable var errorHandler: ErrorHandler

    func body(content: Content) -> some View {
        content.alert(
            Text(alertTitle),
            // 클로저 바인딩 대신 ErrorHandler의 프로퍼티로 KeyPath 바인딩을 만든다
            isPresented: $errorHandler.isPresentingError,
            presenting: errorHandler.currentError
        ) { presentable in
            if presentable.showRetry, let retry = presentable.retryAction {
                Button("다시 시도") {
                    errorHandler.clear()
                    Task { await retry() }
                }
            }
            Button("확인", role: .cancel) {
                errorHandler.clear()
            }
        } message: { presentable in
            Text(ErrorDisplay(presentable.error).message)
        }
    }

    private var alertTitle: LocalizedStringResource {
        errorHandler.currentError.map { ErrorDisplay($0.error).alertTitle } ?? "오류"
    }
}

extension View {
    /// 전역 에러 Alert을 부착한다. 앱 루트 뷰에서 한 번만 호출한다.
    func globalErrorAlert(_ errorHandler: ErrorHandler) -> some View {
        modifier(GlobalErrorAlert(errorHandler: errorHandler))
    }
}
