//
//  AppError.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

/// 앱 전체가 공유하는 통합 에러 타입.
///
/// 계층별 에러(``NetworkError``·``RepositoryError``·``DomainError``)를 감싸기만 하고,
/// 판단(``userMessage``·``isRetryable``)은 각 하위 타입에 위임한다.
/// 새 계층이 생겨도 여기에는 case 하나만 늘어난다.
///
/// 아이콘·제목 같은 UI 어휘는 이 타입이 갖지 않는다 — ``ErrorDisplay``가 담당한다.
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
/// - SeeAlso: ``Loadable``, ``ErrorHandler``, ``ErrorStateView``
enum AppError: Error, LocalizedError, Equatable {

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

    // MARK: - LocalizedError

    var errorDescription: String? {
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

    // MARK: - Presentation

    /// 사용자에게 표시할 메시지.
    ///
    /// 표시 시점에 해석되도록 `LocalizedStringResource`로 둔다 — `String`으로 만들면
    /// 생성 시점 로케일로 굳고, `Text`가 지역화 경로를 타지 않는다.
    var userMessage: LocalizedStringResource {
        switch self {
        case .network(let error):
            return error.userMessage
        case .repository(let error):
            return error.userMessage
        case .domain(let error):
            return error.userMessage
        case .cancelled:
            return ""
        case .unknown:
            return "일시적인 오류가 발생했어요. \n다시 시도해주세요."
        }
    }

    /// 재시도 버튼 노출 여부
    var isRetryable: Bool {
        switch self {
        case .network(let error):
            return error.isRetryable
        case .repository(let error):
            return error.isRetryable
        case .domain(let error):
            return error.isRetryable
        case .cancelled:
            return false
        case .unknown:
            return true
        }
    }

    /// 세션을 파기하고 로그인 화면으로 돌려보내야 하는지.
    ///
    /// 서버가 토큰을 거부한 경우만 해당한다. 전송 계층 실패(``NetworkError/noNetwork``·
    /// ``NetworkError/timeout``)는 토큰이 무효라는 근거가 아니므로 세션을 건드리지 않는다.
    var requiresReauth: Bool {
        if case .network(.unauthorized) = self { return true }
        return false
    }

    /// 무시해야 할 취소인지
    var isCancellation: Bool {
        if case .cancelled = self { return true }
        return false
    }

    // MARK: - Normalization

    /// 임의의 `Error`를 `AppError`로 정규화한다.
    ///
    /// Repository는 에러를 가공하지 않고 그대로 전파하므로, `URLError`·`DecodingError` 같은
    /// 프레임워크 에러가 Presentation까지 올라온다. 그 흡수를 각 ViewModel의 catch 블록이
    /// 제각기 하지 않도록 이 한 곳으로 모은 것이다.
    static func from(_ error: Error) -> AppError {
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
            return .repository(.decodingError(detail: describe(decodingError)))
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
