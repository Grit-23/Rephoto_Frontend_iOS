//
//  DomainError.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

/// 비즈니스 규칙 위반 에러.
///
/// 사용자가 **화면 안에서 스스로 해결할 수 있는** 문제를 표현한다.
/// 따라서 전역 Alert(``ErrorHandler``)이 아니라 인라인(``Loadable``·필드 메시지)으로 표시한다.
///
/// - SeeAlso: ``AppError``, ``Loadable``
enum DomainError: Error, LocalizedError, Equatable {

    // MARK: - 로그인

    /// 아이디 또는 비밀번호가 비어 있음
    case emptyCredentials

    // MARK: - 민감한 사진

    /// 이 기기에서 생체/패스코드 인증을 사용할 수 없음
    case biometricUnavailable(reason: String?)

    // MARK: - 기타

    /// 케이스로 승격되지 않은 일회성 안내
    case custom(message: String)

    /// 사용자에게 표시할 메시지.
    ///
    /// 도메인 안내는 문구 자체가 곧 사용자 대상이라 개발자용 설명과 내용이 같다.
    /// 표시 시점 해석을 위해 이쪽이 원본이고 ``errorDescription``이 여기서 파생된다.
    var userMessage: LocalizedStringResource {
        switch self {
        case .emptyCredentials:
            return "아이디와 비밀번호를 입력해주세요."
        // reason은 LocalAuthentication이 이미 시스템 로케일로 지역화해 넘겨준 문장이므로
        // 카탈로그를 태우지 않고 그대로 표시한다 (런타임 값이라 키 추출 대상도 아니다)
        case .biometricUnavailable(let reason):
            guard let reason else { return "이 기기에서는 인증을 사용할 수 없어요." }
            return LocalizedStringResource(stringLiteral: reason)
        case .custom(let message):
            return LocalizedStringResource(stringLiteral: message)
        }
    }

    var errorDescription: String? {
        String(localized: userMessage)
    }

    /// 입력이나 기기 설정을 바꾸지 않으면 결과가 같으므로 재시도 버튼을 붙이지 않는다.
    var isRetryable: Bool { false }
}
