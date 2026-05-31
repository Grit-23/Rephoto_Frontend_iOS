//
//  NetworkClient.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

actor NetworkClient {
    // MARK: - Dependencies

    /// URLSession 인스턴스 (네트워크 요청 실행)
    private let session: URLSession
    /// 토큰 저장소
    private let tokenStore: TokenStore
    /// 토큰 갱신 서비스
    private let refreshService: TokenRefreshService
    /// 인증 정책 (요청별로 인증 필요 여부 판단)
    private let authPolicy: AuthenticationPolicy
    /// 401 발생 시 최대 재시도 횟수
    private let maxRetryCount: Int
    /// 현재 진행 중인 토큰 갱신 Task
    private var refreshTask: Task<TokenPair, Error>?

    /// 리프레시 실패 시 호출되는 콜백 (예: 강제 로그아웃)
    private var onRefreshFailed: (@Sendable () -> Void)?

    // MARK: - Initializer

    init(
        session: URLSession = .shared,
        tokenStore: TokenStore,
        refreshService: TokenRefreshService,
        authPolicy: AuthenticationPolicy = DefaultAuthenticationPolicy(),
        maxRetryCount: Int = 1
    ) {
        self.session = session
        self.tokenStore = tokenStore
        self.refreshService = refreshService
        self.authPolicy = authPolicy
        self.maxRetryCount = maxRetryCount
    }

    // MARK: - Public API

    /// API 요청을 실행하고 데이터와 HTTP 응답을 반환
    func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await performRequest(urlRequest, retryCount: 0)
    }

    /// 로그아웃 처리 (진행 중 토큰 갱신 취소 + 토큰 삭제)
    func logout() async throws {
        refreshTask?.cancel()
        refreshTask = nil
        try await tokenStore.clear()
    }

    /// 토큰 저장 (로그인 성공 후 호출)
    func saveTokens(accessToken: String, refreshToken: String) async throws {
        try await tokenStore.save(accessToken: accessToken, refreshToken: refreshToken)
    }

    /// 로그인 여부 확인
    func isLoggedIn() async -> Bool {
        await tokenStore.getAccessToken() != nil
    }

    /// 리프레시 실패 콜백 등록
    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {
        onRefreshFailed = handler
    }
}

// MARK: - Private Methods

extension NetworkClient {

    /// 실제 네트워크 요청 수행
    private func performRequest(_ urlRequest: URLRequest, retryCount: Int) async throws -> (Data, HTTPURLResponse) {
        var authenticatedRequest = urlRequest

        // 인증 필요 여부 확인 후 토큰 주입
        if authPolicy.requireAuthentication(urlRequest) {
            if let token = await tokenStore.getAccessToken() {
                authenticatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        // 네트워크 요청 실행
        let (data, response) = try await session.data(for: authenticatedRequest)

        // HTTPURLResponse로 변환
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // 401 에러 응답 처리
        if authPolicy.isUnauthorizedResponse(httpResponse) {
            guard retryCount < maxRetryCount else {
                onRefreshFailed?()
                throw NetworkError.unauthorized
            }

            do {
                _ = try await refreshToken()
                return try await performRequest(urlRequest, retryCount: retryCount + 1)
            } catch is NetworkError {
                onRefreshFailed?()
                throw NetworkError.unauthorized
            } catch is TokenRefreshError {
                onRefreshFailed?()
                throw NetworkError.unauthorized
            } catch {
                throw error
            }
        }

        // 성공 응답 확인
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        return (data, httpResponse)
    }

    /// 토큰 갱신 수행 (Task deduplication으로 중복 방지)
    private func refreshToken() async throws -> TokenPair {
        // 이미 갱신 중이면 기존 Task의 결과를 대기
        if let existTask = refreshTask {
            return try await existTask.value
        }

        // 새 토큰 갱신 Task
        let task = Task<TokenPair, Error> {
            defer { refreshTask = nil }

            guard let refreshToken = await tokenStore.getRefreshToken() else {
                throw NetworkError.unauthorized
            }

            let tokenPair = try await refreshService.refresh(refreshToken)

            try await tokenStore.save(
                accessToken: tokenPair.accessToken,
                refreshToken: tokenPair.refreshToken
            )

            return tokenPair
        }

        refreshTask = task
        return try await task.value
    }
}
