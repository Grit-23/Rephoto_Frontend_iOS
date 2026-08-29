//
//  ErrorHandler.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation
import os

/// 전역 Alert으로 알려야 할 에러의 단일 처리 지점.
///
/// 정규화 → 로깅 → 세션 만료 같은 특수 처리 → Alert 표시를 한 흐름으로 묶는다.
/// 화면 안에서 해결 가능한 실패(목록 로딩 실패, 입력 오류)는 여기가 아니라
/// ``Loadable``로 인라인 표시한다.
///
/// | 기준 | ErrorHandler (Alert) | Loadable (인라인) |
/// |------|---------------------|-------------------|
/// | 작업 흐름 | 끊긴다 | 유지된다 |
/// | 사용자 액션 | 즉시 필요 | 화면에서 해결 가능 |
/// | 예시 | 업로드 실패, 세션 만료 | 목록 로딩 실패, 검색 결과 없음 |
///
/// ## 사용
///
/// ```swift
/// // App — 루트에 한 번만
/// .globalErrorAlert(errorHandler)
///
/// // ViewModel — 생성자로 주입받아 사용
/// catch {
///     errorHandler.handle(error, context: .init(
///         feature: "Home",
///         action: "uploadPhotos",
///         retryAction: { [weak self] in await self?.upload() }
///     ))
/// }
/// ```
///
/// - SeeAlso: ``AppError``, ``PresentableError``, ``Loadable``
@Observable
@MainActor
final class ErrorHandler {

    // MARK: - State

    /// 현재 표시해야 할 에러. `nil`이면 표시할 것이 없다.
    private(set) var currentError: PresentableError?

    /// Alert 표시 여부. `false`로 쓰면 현재 에러를 지운다.
    ///
    /// 뷰에서 `$errorHandler.isPresentingError`로 KeyPath 바인딩을 만들기 위한 프로퍼티다.
    /// 표시 지점에서 `Binding(get:set:)`을 조립하면 body 평가마다 클로저가 새로 할당되고
    /// SwiftUI가 그 바인딩을 비교하지 못해 불필요한 무효화가 발생한다.
    var isPresentingError: Bool {
        get { currentError != nil }
        set { if !newValue { clear() } }
    }

    /// 세션이 만료되어 로그아웃이 필요할 때 호출된다.
    ///
    /// `SessionStore`는 Feature 계층에 있어 Core가 직접 참조할 수 없으므로,
    /// 앱 조립 시점에 주입되는 훅으로 의존 방향을 뒤집는다.
    /// 조립 시 한 번 설정되는 구성값이라 관찰 대상이 아니다 — 클로저는 비교가 불가능해
    /// 관찰 대상으로 두면 대입할 때마다 구독자를 무효화한다.
    @ObservationIgnored
    var onSessionExpired: (@MainActor () -> Void)?

    @ObservationIgnored
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Rephoto_iOS",
        category: "ErrorHandler"
    )

    init() {}

    // MARK: - Handling

    /// 에러를 처리한다. 취소는 조용히 무시하고, 세션 만료는 Alert 대신 로그아웃으로 보낸다.
    func handle(_ error: Error, context: ErrorContext) {
        let appError = AppError.from(error)

        guard !appError.isCancellation else {
            logger.debug("[\(context.feature)/\(context.action)] cancelled")
            return
        }

        log(appError, context: context)

        // 서버가 토큰을 거부한 경우만 세션을 파기한다. 네트워크 단절·타임아웃은
        // 토큰이 무효라는 근거가 아니므로 일반 Alert으로 흘려보낸다.
        if appError.requiresReauth {
            onSessionExpired?()
            return
        }

        currentError = PresentableError(error: appError, context: context)
    }

    /// 표시 중인 에러를 지운다. Alert이 닫힐 때 호출된다.
    func clear() {
        currentError = nil
    }

    // MARK: - Logging

    /// ErrorHandler에 도달한 시점에 이미 "사용자를 멈춰 세울 만한 실패"로 걸러졌으므로
    /// 레벨을 나누지 않는다. 무시 대상(취소)은 위에서 이미 빠져나갔다.
    private func log(_ error: AppError, context: ErrorContext) {
        logger.error("""
        [\(context.feature)/\(context.action)] \(error.errorDescription ?? "Unknown") \
        (retryable: \(error.isRetryable))
        """)
    }
}
