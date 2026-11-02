//
//  ErrorHandler.swift
//  DesignSystem
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation
import os
import RephotoFoundation

/// 전역 Alert으로 알려야 할 에러의 단일 처리 지점.
///
/// 정규화 → 로깅 → 세션 만료 같은 특수 처리 → Alert 표시를 한 흐름으로 묶는다.
/// 화면 안에서 해결 가능한 실패(목록 로딩 실패, 입력 오류)는 여기가 아니라
/// `Loadable` + ``ErrorStateView``로 인라인 표시한다.
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
/// // ViewModel — 생성자로 주입받아 사용. feature · action은 기본값(#fileID · #function)으로 충분하다
/// catch {
///     errorHandler.handle(error, retry: { [weak self] in await self?.upload() })
/// }
/// ```
///
/// 모듈 기본 격리가 MainActor이므로 `@MainActor`를 따로 붙이지 않는다.
///
/// - SeeAlso: `AppError`, `Loadable`
@Observable
public final class ErrorHandler {

    // MARK: - State

    /// 현재 표시해야 할 에러. `nil`이면 표시할 것이 없다.
    public private(set) var currentError: AppError?

    /// 현재 에러를 재시도할 동작. 새 에러나 닫기 동작이 이전 클로저를 대체한다.
    private(set) var retryAction: (() async -> Void)?

    /// 재시도 버튼 표시 여부 — 에러가 재시도 가능하고 되돌릴 동작이 있을 때만
    public var showRetry: Bool {
        currentError?.isRetryable == true && retryAction != nil
    }

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
    /// `SessionStore`는 Domain 계층에 있어 여기서 직접 참조할 수 없으므로,
    /// 앱 조립 시점에 주입되는 훅으로 의존 방향을 뒤집는다.
    /// 조립 시 한 번 설정되는 구성값이라 관찰 대상이 아니다 — 클로저는 비교가 불가능해
    /// 관찰 대상으로 두면 대입할 때마다 구독자를 무효화한다.
    @ObservationIgnored
    public var onSessionExpired: (@MainActor () -> Void)?

    @ObservationIgnored
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Rephoto",
        category: "ErrorHandler"
    )

    public init() {}

    // MARK: - Handling

    /// 에러를 처리한다. 취소는 조용히 무시하고, 세션 만료는 Alert 대신 로그아웃으로 보낸다.
    ///
    /// `feature` · `action`은 로그에서 발생 위치를 구분하기 위한 값이다.
    /// 기본값이 호출 지점의 파일 · 함수라 보통은 넘기지 않는다.
    public func handle(
        _ error: Error,
        feature: String = #fileID,
        action: String = #function,
        retry: (() async -> Void)? = nil
    ) {
        let appError = AppError.from(error)

        guard !appError.isCancellation else {
            logger.debug("[\(feature)/\(action)] cancelled")
            return
        }

        log(appError, feature: feature, action: action)

        // 서버가 토큰을 거부한 경우만 세션을 파기한다. 네트워크 단절·타임아웃은
        // 토큰이 무효라는 근거가 아니므로 일반 Alert으로 흘려보낸다.
        if appError.requiresReauth {
            onSessionExpired?()
            return
        }

        currentError = appError
        retryAction = retry
    }

    /// 표시 중인 에러를 지운다. Alert이 닫힐 때 호출된다.
    func clear() {
        currentError = nil
        retryAction = nil
    }

    // MARK: - Logging

    /// ErrorHandler에 도달한 시점에 이미 "사용자를 멈춰 세울 만한 실패"로 걸러졌으므로
    /// 레벨을 나누지 않는다. 무시 대상(취소)은 위에서 이미 빠져나갔다.
    private func log(_ error: AppError, feature: String, action: String) {
        logger.error("""
        [\(feature)/\(action)] \(error.errorDescription ?? "Unknown") \
        (retryable: \(error.isRetryable))
        """)
    }
}
