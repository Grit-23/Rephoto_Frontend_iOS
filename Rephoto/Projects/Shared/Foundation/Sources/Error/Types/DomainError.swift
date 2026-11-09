//
//  DomainError.swift
//  RephotoFoundation
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

/// 비즈니스 규칙 위반 에러.
///
/// 사용자가 **화면 안에서 스스로 해결할 수 있는** 문제를 표현한다.
/// 따라서 전역 Alert(`ErrorHandler`)이 아니라 인라인(``Loadable``·필드 메시지)으로 표시한다.
///
/// 일회성 안내를 문자열로 흘리는 case는 두지 않는다 — 새 규칙은 case로 승격해
/// 호출부가 어떤 위반인지 타입으로 구분할 수 있게 한다.
///
/// 사용자 문구는 ``AppError/userMessage``가 원본이다. 여기 `errorDescription`은
/// 다른 계층 에러와 마찬가지로 로그용 진단만 담는다.
///
/// - SeeAlso: ``AppError``, ``Loadable``
public enum DomainError: Error, LocalizedError, Equatable, Sendable {

    // MARK: - 로그인

    /// 아이디 또는 비밀번호가 비어 있음
    case emptyCredentials

    // MARK: - 민감한 사진

    /// 이 기기에서 생체/패스코드 인증을 사용할 수 없음.
    /// `reason`은 LocalAuthentication이 넘겨준 시스템 안내 문장이다.
    case biometricUnavailable(reason: String?)

    // MARK: - 사진 업로드

    case uploadPreparationFailed(count: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyCredentials:
            return "비어 있는 자격 증명"
        case .biometricUnavailable(let reason):
            return "생체 인증 사용 불가: \(reason ?? "사유 없음")"
        case .uploadPreparationFailed(let count):
            return "업로드 준비 실패: \(count)장"
        }
    }
}
