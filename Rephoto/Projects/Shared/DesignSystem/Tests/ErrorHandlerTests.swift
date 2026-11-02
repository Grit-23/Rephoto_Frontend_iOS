//
//  ErrorHandlerTests.swift
//  DesignSystemTests
//
//  Created by Doyeon Kim on 11/2/26.
//

import Foundation
import RephotoFoundation
import Testing
@testable import DesignSystem

@Suite("ErrorHandler")
struct ErrorHandlerTests {
    @Test("취소는 Alert이나 세션 만료 처리를 만들지 않는다")
    func cancellationIsIgnored() {
        let handler = ErrorHandler()
        var sessionExpired = false
        handler.onSessionExpired = { sessionExpired = true }

        handler.handle(CancellationError(), retry: {})
        handler.handle(URLError(.cancelled), retry: {})
        handler.handle(AppError.cancelled, retry: {})

        #expect(handler.currentError == nil)
        #expect(handler.retryAction == nil)
        #expect(handler.isPresentingError == false)
        #expect(sessionExpired == false)
    }

    @Test("취소는 이미 표시 중인 오류와 재시도를 덮어쓰지 않는다")
    func cancellationPreservesCurrentError() async throws {
        let handler = ErrorHandler()
        var retryCount = 0
        handler.handle(NetworkError.timeout, retry: { retryCount += 1 })

        handler.handle(CancellationError())

        #expect(handler.currentError == .network(.timeout))
        #expect(handler.showRetry)
        let retry = try #require(handler.retryAction)
        await retry()
        #expect(retryCount == 1)
    }

    @Test("인증 만료는 Alert 대신 세션 만료 훅을 한 번 호출한다")
    func unauthorizedExpiresSession() {
        let handler = ErrorHandler()
        var expirationCount = 0
        handler.onSessionExpired = { expirationCount += 1 }

        handler.handle(NetworkError.unauthorized, retry: {})

        #expect(expirationCount == 1)
        #expect(handler.currentError == nil)
        #expect(handler.retryAction == nil)
        #expect(handler.isPresentingError == false)
    }

    @Test("일반 오류는 정규화한 상태와 전달받은 재시도를 표시한다")
    func generalErrorPublishesState() async throws {
        let handler = ErrorHandler()
        var sessionExpired = false
        var retryCount = 0
        handler.onSessionExpired = { sessionExpired = true }

        handler.handle(
            URLError(.timedOut),
            feature: "Home",
            action: "fetchPhotos",
            retry: { retryCount += 1 }
        )

        #expect(handler.currentError == .network(.timeout))
        #expect(handler.isPresentingError)
        #expect(handler.showRetry)
        #expect(sessionExpired == false)
        let retry = try #require(handler.retryAction)
        await retry()
        #expect(retryCount == 1)
    }

    @Test("재시도는 가능한 오류에 동작이 전달된 경우에만 표시한다")
    func retryRequiresRetryableErrorAndAction() {
        let cases: [(AppError, Bool, Bool)] = [
            (.network(.timeout), true, true),
            (.network(.timeout), false, false),
            (.domain(.emptyCredentials), true, false),
            (.domain(.emptyCredentials), false, false),
        ]

        for (error, hasRetry, expected) in cases {
            let handler = ErrorHandler()
            handler.handle(error, retry: hasRetry ? {} : nil)

            #expect(handler.showRetry == expected)
        }
    }

    @Test("clear는 표시 상태와 재시도 동작을 함께 지운다")
    func clearRemovesErrorAndRetry() {
        let handler = ErrorHandler()
        handler.handle(NetworkError.timeout, retry: {})

        handler.clear()

        #expect(handler.currentError == nil)
        #expect(handler.retryAction == nil)
        #expect(handler.isPresentingError == false)
        #expect(handler.showRetry == false)
    }

    @Test("Alert 표시 바인딩을 닫으면 오류와 재시도 동작을 지운다")
    func dismissingAlertClearsState() {
        let handler = ErrorHandler()
        handler.handle(NetworkError.noNetwork, retry: {})

        handler.isPresentingError = false

        #expect(handler.currentError == nil)
        #expect(handler.retryAction == nil)
        #expect(handler.showRetry == false)
    }

    @Test("같은 오류라도 새 재시도가 없으면 이전 동작이 남지 않는다")
    func replacingErrorWithoutRetryRemovesPreviousAction() {
        let handler = ErrorHandler()
        handler.handle(NetworkError.timeout, retry: {})

        handler.handle(NetworkError.timeout)

        #expect(handler.currentError == .network(.timeout))
        #expect(handler.isPresentingError)
        #expect(handler.retryAction == nil)
        #expect(handler.showRetry == false)
    }

    @Test("새 오류의 재시도는 이전 동작을 대체한다")
    func replacingErrorUsesNewRetry() async throws {
        let handler = ErrorHandler()
        var previousRetryCount = 0
        var newRetryCount = 0
        handler.handle(NetworkError.timeout, retry: { previousRetryCount += 1 })

        handler.handle(NetworkError.noNetwork, retry: { newRetryCount += 1 })
        let retry = try #require(handler.retryAction)
        await retry()

        #expect(handler.currentError == .network(.noNetwork))
        #expect(previousRetryCount == 0)
        #expect(newRetryCount == 1)
    }
}
