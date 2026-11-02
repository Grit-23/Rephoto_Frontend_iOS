//
//  NetworkError.swift
//  RephotoFoundation
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

/// 네트워크 계층에서 발생하는 에러.
///
/// `NetworkClient`(actor)가 던지며, 전송 실패(`URLError`)는 ``transientFailure(from:)``으로
/// 이 타입에 흡수된다. 상위에서는 ``AppError/network(_:)``로 감싸 다룬다.
public enum NetworkError: Error, LocalizedError, Equatable, Sendable {

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

    public var errorDescription: String? {
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
