//
//  AppError.swift
//  RephotoFoundation
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

/// 앱 전체가 공유하는 통합 에러 타입.
///
/// 계층별 에러(``NetworkError``·``RepositoryError``·``DomainError``)를 감싸고,
/// 사용자 문구와 재시도 정책을 한 곳에서 결정한다.
///
/// 아이콘·제목 같은 UI 어휘는 DesignSystem의 `AppError+Display`가 담당한다.
///
/// Data 계층은 이 타입을 알지 못한 채 자기 계층의 에러만 던지고,
/// 정규화는 ``from(_:)`` 한 곳에서 일어난다.
///
/// ## 사용
///
/// ```swift
/// do {
///     items = .loaded(try await useCase.execute())
/// } catch {
///     guard !error.isCancellation else { return }
///     items = .failed(AppError.from(error))
/// }
/// ```
///
/// - SeeAlso: ``Loadable``
public enum AppError: Error, LocalizedError, Equatable {

    /// 네트워크 계층 (전송·인증)
    case network(NetworkError)

    /// Data 계층 (디코딩·응답 무결성)
    case repository(RepositoryError)

    /// 비즈니스 규칙 위반 — 인라인으로 표시한다
    case domain(DomainError)

    /// 작업 취소 — 사용자에게 표시하지 않는다
    case cancelled

    /// 분류되지 않은 에러
    case unknown(message: String)

    // MARK: - Presentation

    /// 로그용 개발자 설명은 원래 계층 에러에서 가져온다.
    public var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.errorDescription
        case .repository(let error):
            return error.errorDescription
        case .domain(let error):
            return error.errorDescription
        case .cancelled:
            return "작업이 취소되었습니다."
        case .unknown(let message):
            return message
        }
    }

    /// 사용자에게 표시할 메시지. 표시 시점에 지역화하며 내부 진단 정보는 노출하지 않는다.
    public var userMessage: LocalizedStringResource {
        switch self {
        case .network(.unauthorized):
            return "세션이 만료되었어요. \n다시 로그인해주세요."
        case .network(.httpError(let statusCode, _)):
            if (400..<500).contains(statusCode) {
                return "요청을 처리할 수 없어요. \n잠시 후 다시 시도해주세요."
            }
            return "서버에 일시적인 문제가 있어요. \n잠시 후 다시 시도해주세요."
        case .network(.invalidResponse):
            return "서버 응답을 이해하지 못했어요. \n잠시 후 다시 시도해주세요."
        case .network(.noNetwork):
            return "인터넷 연결을 확인해주세요."
        case .network(.timeout):
            return "서버 응답이 늦어지고 있어요. \n잠시 후 다시 시도해주세요."
        case .repository:
            return "정보를 불러오지 못했어요. \n잠시 후 다시 시도해주세요."
        case .domain(.emptyCredentials):
            return "아이디와 비밀번호를 입력해주세요."
        case .domain(.biometricUnavailable(let reason)):
            guard let reason else { return "이 기기에서는 인증을 사용할 수 없어요." }
            // LocalAuthentication이 이미 시스템 로케일로 지역화한 안내다.
            return LocalizedStringResource(stringLiteral: reason)
        case .domain(.uploadPreparationFailed(let count)):
            return "사진 \(count)장은 올리지 못했어요. \n다시 선택해주세요."
        case .cancelled:
            return ""
        case .unknown:
            return "일시적인 오류가 발생했어요. \n다시 시도해주세요."
        }
    }

    /// 재시도 버튼 노출 여부
    public var isRetryable: Bool {
        switch self {
        case .network(.unauthorized), .repository, .domain, .cancelled:
            return false
        case .network(.httpError(let statusCode, _)):
            return !(400..<500).contains(statusCode)
        case .network, .unknown:
            return true
        }
    }

    /// 세션을 파기하고 로그인 화면으로 돌려보내야 하는지.
    ///
    /// 서버가 토큰을 거부한 경우만 해당한다. 전송 계층 실패(``NetworkError/noNetwork``·
    /// ``NetworkError/timeout``)는 토큰이 무효라는 근거가 아니므로 세션을 건드리지 않는다.
    public var requiresReauth: Bool {
        if case .network(.unauthorized) = self { return true }
        return false
    }

    /// 무시해야 할 취소인지
    public var isCancellation: Bool {
        if case .cancelled = self { return true }
        return false
    }

    // MARK: - Normalization

    /// 임의의 `Error`를 `AppError`로 정규화한다.
    ///
    /// Repository는 에러를 가공하지 않고 그대로 전파하므로, `URLError`·`DecodingError` 같은
    /// 프레임워크 에러가 Presentation까지 올라온다. 그 흡수를 각 ViewModel의 catch 블록이
    /// 제각기 하지 않도록 이 한 곳으로 모은 것이다.
    public static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if error.isCancellation {
            return .cancelled
        }
        if let networkError = error as? NetworkError {
            return .network(networkError)
        }
        if let repositoryError = error as? RepositoryError {
            return .repository(repositoryError)
        }
        if let domainError = error as? DomainError {
            return .domain(domainError)
        }
        if let urlError = error as? URLError {
            // 전용 케이스가 없는 코드(DNS 실패 등)는 분류 실패로 남긴다.
            // URLError.errorCode는 HTTP 상태 코드가 아니므로(cannotFindHost = -1003)
            // httpError에 넣으면 상태 코드 기반 문구·재시도 판단이 전부 어긋난다
            guard let networkError = NetworkError.transientFailure(from: urlError) else {
                return .unknown(message: urlError.localizedDescription)
            }
            return .network(networkError)
        }
        if let decodingError = error as? DecodingError {
            return .repository(.invalidData(detail: describe(decodingError)))
        }
        return .unknown(message: error.localizedDescription)
    }

    /// 디코딩 실패 지점을 로그에서 바로 찾을 수 있도록 코딩 경로를 문자열로 남긴다.
    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            return "Missing key: \(path(context.codingPath, appending: key.stringValue))"
        case .typeMismatch(let type, let context):
            return "Type mismatch: expected \(type) at \(path(context.codingPath))"
        case .valueNotFound(let type, let context):
            return "Value not found: \(type) at \(path(context.codingPath))"
        case .dataCorrupted(let context):
            return "Data corrupted at \(path(context.codingPath)): \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error"
        }
    }

    private static func path(_ codingPath: [CodingKey], appending key: String? = nil) -> String {
        let components = codingPath.map(\.stringValue) + [key].compactMap { $0 }
        return components.isEmpty ? "(root)" : components.joined(separator: ".")
    }
}
