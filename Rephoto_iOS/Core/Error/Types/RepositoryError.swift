//
//  RepositoryError.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

/// Data 계층에서 발생하는 에러.
///
/// 응답을 받긴 했지만 도메인 모델로 옮길 수 없는 경우를 표현한다.
/// 전송 자체의 실패는 ``NetworkError``가 담당한다.
enum RepositoryError: Error, LocalizedError, Sendable, Equatable {

    /// 응답 데이터 디코딩 실패
    case decodingError(detail: String?)

    /// 디코딩은 성공했지만 내용이 의미상 유효하지 않음 (필수 필드 누락, URL 파싱 실패 등)
    case invalidResponse(detail: String?)

    var errorDescription: String? {
        switch self {
        case .decodingError(let detail):
            return "데이터 파싱 실패: \(detail ?? "알 수 없는 오류")"
        case .invalidResponse(let detail):
            return "서버 응답이 유효하지 않습니다: \(detail ?? "알 수 없는 오류")"
        }
    }

    /// 사용자에게 표시할 메시지.
    ///
    /// 파싱 실패의 원인은 사용자가 해결할 수 없으므로 내부 상세(``errorDescription``)는
    /// 로그로만 남기고 화면에는 공통 문구를 보여준다.
    var userMessage: LocalizedStringResource {
        "정보를 불러오지 못했어요. \n잠시 후 다시 시도해주세요."
    }

    /// 같은 응답을 다시 받아도 결과가 같으므로 재시도 대상이 아니다.
    var isRetryable: Bool { false }
}
