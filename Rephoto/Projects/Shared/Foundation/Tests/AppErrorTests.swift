//
//  AppErrorTests.swift
//  RephotoFoundationTests
//
//  Created by Doyeon Kim on 11/2/26.
//

import Foundation
import Testing
@testable import RephotoFoundation

/// `AppError.from(_:)` 정규화 규칙 검증.
///
/// Repository는 에러를 가공하지 않고 던지므로 URLError · DecodingError 같은 프레임워크 에러가
/// 그대로 올라온다. 이 분류가 틀리면 문구 · 재시도 · 세션 파기 판단이 전부 어긋난다.
@Suite("AppError.from")
struct AppErrorFromTests {

    @Test("AppError는 다시 감싸지 않고 그대로 돌려준다")
    func passesThroughAppError() {
        let original = AppError.network(.timeout)

        #expect(AppError.from(original) == original)
    }

    @Test("취소는 CancellationError와 URLError(.cancelled) 모두 .cancelled로 정규화한다")
    func mapsCancellation() {
        #expect(AppError.from(CancellationError()) == .cancelled)
        #expect(AppError.from(URLError(.cancelled)) == .cancelled)
    }

    @Test("계층 에러는 대응하는 case로 감싼다")
    func wrapsLayerErrors() {
        #expect(AppError.from(NetworkError.unauthorized) == .network(.unauthorized))
        #expect(
            AppError.from(RepositoryError.invalidData(detail: "imageUrl 파싱 실패"))
                == .repository(.invalidData(detail: "imageUrl 파싱 실패"))
        )
        #expect(AppError.from(DomainError.emptyCredentials) == .domain(.emptyCredentials))
    }

    @Test(
        "전송 실패 URLError는 전용 NetworkError 케이스로 흡수한다",
        arguments: [
            (URLError.Code.notConnectedToInternet, NetworkError.noNetwork),
            (.networkConnectionLost, .noNetwork),
            (.dataNotAllowed, .noNetwork),
            (.timedOut, .timeout),
        ]
    )
    func mapsTransientURLErrors(code: URLError.Code, expected: NetworkError) {
        #expect(AppError.from(URLError(code)) == .network(expected))
    }

    /// URLError.errorCode(cannotFindHost = -1003)는 HTTP 상태 코드가 아니다.
    /// httpError에 끼워 넣으면 상태 코드 기반 문구·재시도 판단이 어긋나므로 분류 실패로 남긴다.
    @Test("전용 케이스가 없는 URLError는 httpError가 아니라 .unknown으로 남긴다")
    func leavesOtherURLErrorsUnknown() {
        let error = URLError(.cannotFindHost)

        #expect(AppError.from(error) == .unknown(message: error.localizedDescription))
    }

    @Test("DecodingError는 코딩 경로를 담아 .repository(.invalidData)로 정규화한다")
    func mapsDecodingErrorWithCodingPath() throws {
        struct Photo: Decodable { let imageUrl: String }
        let json = Data(#"[{"id": 1}]"#.utf8)

        let thrown = #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode([Photo].self, from: json)
        }
        let decodingError = try #require(thrown)

        guard case .repository(.invalidData(let detail)) = AppError.from(decodingError) else {
            Issue.record("repository(.invalidData)가 아님: \(AppError.from(decodingError))")
            return
        }
        #expect(detail.hasPrefix("Missing key:"))
        #expect(detail.hasSuffix("imageUrl"), "로그에서 실패 지점을 찾을 수 있도록 키 이름이 끝에 와야 한다")
    }

    @Test("분류되지 않는 에러는 localizedDescription을 담아 .unknown으로 남긴다")
    func mapsUnknownErrors() {
        struct SomethingElse: Error {}
        let error = SomethingElse()

        #expect(AppError.from(error) == .unknown(message: error.localizedDescription))
    }
}

/// `AppError`가 사용자 문구와 재시도 정책을 일관되게 적용하는지 검증.
@Suite("AppError 표현 정책")
struct AppErrorPresentationTests {

    @Test("세션 파기는 서버가 토큰을 거부한 unauthorized만 요구한다")
    func requiresReauthOnlyForUnauthorized() {
        #expect(AppError.network(.unauthorized).requiresReauth)
        #expect(AppError.network(.noNetwork).requiresReauth == false)
        #expect(AppError.network(.timeout).requiresReauth == false)
        #expect(AppError.network(.httpError(statusCode: 403, data: Data())).requiresReauth == false)
    }

    @Test(
        "사용자 문구와 재시도 정책을 에러별로 유지한다",
        arguments: [
            (AppError.network(.invalidResponse), LocalizedStringResource("서버 응답을 이해하지 못했어요. \n잠시 후 다시 시도해주세요."), true),
            (.network(.unauthorized), "세션이 만료되었어요. \n다시 로그인해주세요.", false),
            (.network(.httpError(statusCode: 404, data: Data())), "요청을 처리할 수 없어요. \n잠시 후 다시 시도해주세요.", false),
            (.network(.httpError(statusCode: 500, data: Data())), "서버에 일시적인 문제가 있어요. \n잠시 후 다시 시도해주세요.", true),
            (.network(.noNetwork), "인터넷 연결을 확인해주세요.", true),
            (.network(.timeout), "서버 응답이 늦어지고 있어요. \n잠시 후 다시 시도해주세요.", true),
            (.repository(.invalidData(detail: "private detail")), "정보를 불러오지 못했어요. \n잠시 후 다시 시도해주세요.", false),
            (.domain(.emptyCredentials), "아이디와 비밀번호를 입력해주세요.", false),
            (.domain(.biometricUnavailable(reason: nil)), "이 기기에서는 인증을 사용할 수 없어요.", false),
            (.domain(.biometricUnavailable(reason: "Face ID를 설정해주세요.")), "Face ID를 설정해주세요.", false),
            (.cancelled, "", false),
            (.unknown(message: "private detail"), "일시적인 오류가 발생했어요. \n다시 시도해주세요.", true),
        ]
    )
    func preservesPresentationPolicy(error: AppError, message: LocalizedStringResource, retryable: Bool) {
        #expect(String(localized: error.userMessage) == String(localized: message))
        #expect(error.isRetryable == retryable)
    }

    @Test("개발자 설명은 감싼 계층 에러의 진단 정보를 보존한다")
    func preservesLayerDiagnostics() {
        let networkError = NetworkError.httpError(statusCode: 500, data: Data())
        let repositoryError = RepositoryError.invalidData(detail: "imageUrl 파싱 실패")
        let domainError = DomainError.biometricUnavailable(reason: nil)

        #expect(AppError.network(networkError).errorDescription == networkError.errorDescription)
        #expect(AppError.repository(repositoryError).errorDescription == repositoryError.errorDescription)
        #expect(AppError.domain(domainError).errorDescription == domainError.errorDescription)
    }

    @Test(".unknown은 전달받은 메시지를 개발자 설명으로 쓰고 사용자에게는 공통 문구를 보여준다")
    func unknownKeepsMessageForLogsOnly() {
        let appError = AppError.unknown(message: "raw failure")

        #expect(appError.errorDescription == "raw failure")
        #expect(String(localized: appError.userMessage) != "raw failure")
    }

    @Test("취소는 표시할 문구가 없고 isCancellation만 참이다")
    func cancellationHasNoUserMessage() {
        #expect(AppError.cancelled.isCancellation)
        #expect(String(localized: AppError.cancelled.userMessage).isEmpty)
        #expect(AppError.network(.timeout).isCancellation == false)
    }
}
