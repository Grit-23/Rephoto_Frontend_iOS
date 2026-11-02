//
//  AppError+Display.swift
//  DesignSystem
//
//  Created by Doyeon Kim on 11/2/26.
//

import Foundation
import RephotoFoundation

/// `AppError`를 화면 어휘(제목 · 아이콘)로 옮기는 매핑.
///
/// Foundation의 에러 타입이 SF Symbol 이름 같은 표현 계층 어휘를 들지 않도록 여기서만 해석한다.
/// 사용자 문구(`userMessage`)와 재시도 정책(`isRetryable`)은 `AppError`가 원본이다.
extension AppError {

    /// 전체 화면 에러 상태(``ErrorStateView``)의 한 줄 제목
    var title: LocalizedStringResource {
        switch self {
        case .network(.noNetwork):
            return "인터넷에 연결되어 있지 않아요"
        case .network(.timeout):
            return "응답이 너무 늦어요"
        case .network(.unauthorized):
            return "다시 로그인이 필요해요"
        // 도메인 규칙 위반은 문구 자체가 안내라 제목으로 올린다
        case .domain:
            return userMessage
        case .network, .repository, .cancelled, .unknown:
            return "불러오지 못했어요"
        }
    }

    /// SF Symbol 이름 — 사용자에게 노출되는 문구가 아니므로 지역화 대상이 아니다
    var systemImage: String {
        switch self {
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

    /// Alert 타이틀. 도메인 안내와 실패를 구분한다 — 전자는 사용자가 화면에서 해결할 수 있다.
    var alertTitle: LocalizedStringResource {
        if case .domain = self { return "알림" }
        return "오류"
    }
}
