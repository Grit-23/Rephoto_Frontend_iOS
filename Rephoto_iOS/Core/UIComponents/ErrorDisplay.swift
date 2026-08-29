//
//  ErrorDisplay.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

/// ``AppError``를 화면 표현으로 옮기는 매핑.
///
/// 아이콘 이름 같은 UI 어휘를 에러 타입이 들고 있으면 Core의 에러 정의가 표현 계층에 묶인다.
/// 그 매핑을 여기로 분리해 `AppError`는 "무엇이 실패했는가"만 알게 한다.
///
/// 문구는 표시 시점에 해석되도록 `LocalizedStringResource`로 노출한다.
///
/// - SeeAlso: ``ErrorStateView``, ``AppError``
struct ErrorDisplay {
    private let error: AppError

    init(_ error: AppError) {
        self.error = error
    }

    /// 전체 화면 에러 상태의 한 줄 제목
    var title: LocalizedStringResource {
        switch error {
        case .network(.noNetwork):
            return "인터넷에 연결되어 있지 않아요"
        case .network(.timeout):
            return "응답이 너무 늦어요"
        case .network(.unauthorized):
            return "다시 로그인이 필요해요"
        // 도메인 규칙 위반은 문구 자체가 안내라 제목으로 올린다
        case .domain(let domainError):
            return domainError.userMessage
        case .network, .repository, .cancelled, .unknown:
            return "불러오지 못했어요"
        }
    }

    var message: LocalizedStringResource {
        error.userMessage
    }

    /// SF Symbol 이름 — 사용자에게 노출되는 문구가 아니므로 지역화 대상이 아니다
    var systemImage: String {
        switch error {
        case .network(.noNetwork), .network(.timeout):
            return "wifi.exclamationmark"
        case .network(.unauthorized):
            return "person.crop.circle.badge.exclamationmark"
        case .domain:
            return "info.circle"
        case .network, .repository, .cancelled, .unknown:
            return "exclamationmark.triangle"
        }
    }

    /// Alert 타이틀.
    ///
    /// 도메인 안내와 실패를 구분한다 — 전자는 사용자가 화면에서 해결할 수 있는 상황이다.
    var alertTitle: LocalizedStringResource {
        if case .domain = error { return "알림" }
        return "오류"
    }
}
