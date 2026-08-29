//
//  NetworkError.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

/// 네트워크 계층에서 발생하는 에러.
///
/// `NetworkClient`(actor)가 던지며, 전송 실패(`URLError`)는 ``transientFailure(from:)``으로
/// 이 타입에 흡수된다. 상위에서는 ``AppError/network(_:)``로 감싸 다룬다.
enum NetworkError: Error, LocalizedError, Sendable, Equatable {

    /// URLResponse가 HTTPURLResponse로 변환 불가
    case invalidResponse

    /// 인증 실패 (401 재시도 초과 또는 refreshToken 없음)
    case unauthorized

    /// HTTP 에러 응답 (2xx 외 상태 코드)
    case httpError(statusCode: Int, data: Data)

    /// 인터넷 연결 없음 (요청이 서버에 도달하지 못함)
    case noNetwork

    /// 요청 시간 초과
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "유효하지 않은 서버 응답입니다."
        case .unauthorized:
            return "인증이 필요합니다. \n다시 로그인해 주세요."
        case .httpError(let statusCode, _):
            return "HTTP 오류가 발생했습니다. \n(상태 코드: \(statusCode))"
        case .noNetwork:
            return "네트워크 연결이 없습니다."
        case .timeout:
            return "요청 시간이 초과되었습니다."
        }
    }
}

// MARK: - NetworkError + URLError

extension NetworkError {
    /// 전송 계층 실패(`URLError`)를 대응하는 전용 케이스로 변환한다.
    ///
    /// 요청이 서버에 도달하지 못한 실패이므로 저장된 토큰의 유효성과는 무관하다.
    ///
    /// 전용 케이스가 없는 코드(취소, DNS 실패 등)는 `nil`을 반환한다 — 억지로 이 타입에
    /// 끼워 맞추면 `errorCode`가 HTTP 상태 코드 자리에 들어가 문구·재시도 판단이 어긋난다.
    /// 판단은 호출부(``AppError/from(_:)``)에 맡긴다.
    static func transientFailure(from error: URLError) -> NetworkError? {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .noNetwork
        case .timedOut:
            return .timeout
        default:
            return nil
        }
    }
}

// MARK: - NetworkError + Presentation

extension NetworkError {
    /// 사용자에게 표시할 메시지.
    ///
    /// 표시 시점에 해석되도록 `LocalizedStringResource`로 둔다 — `String`으로 만들면
    /// 생성 시점 로케일로 굳고, `Text`가 지역화 경로를 타지 않는다.
    /// (개발자용 상세는 ``errorDescription``이 담당한다.)
    var userMessage: LocalizedStringResource {
        switch self {
        case .unauthorized:
            return "세션이 만료되었어요. \n다시 로그인해주세요."
        case .httpError(let statusCode, _):
            switch statusCode {
            case 400..<500:
                return "요청을 처리할 수 없어요. \n잠시 후 다시 시도해주세요."
            default:
                return "서버에 일시적인 문제가 있어요. \n잠시 후 다시 시도해주세요."
            }
        case .invalidResponse:
            return "서버 응답을 이해하지 못했어요. \n잠시 후 다시 시도해주세요."
        case .noNetwork:
            return "인터넷 연결을 확인해주세요."
        case .timeout:
            return "서버 응답이 늦어지고 있어요. \n잠시 후 다시 시도해주세요."
        }
    }

    /// 재시도 가능 여부.
    ///
    /// 4xx는 같은 요청을 반복해도 결과가 같으므로 재시도 대상이 아니다.
    var isRetryable: Bool {
        switch self {
        case .unauthorized:
            return false
        case .httpError(let statusCode, _):
            return !(400..<500).contains(statusCode)
        case .invalidResponse, .noNetwork, .timeout:
            return true
        }
    }
}
