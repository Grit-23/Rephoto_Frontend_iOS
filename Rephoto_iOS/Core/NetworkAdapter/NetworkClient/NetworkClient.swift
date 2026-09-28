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
    /// 세션 종료 통지를 이미 보냈는지 여부. 새 토큰을 확보하면 다시 false가 된다.
    private var hasNotifiedRefreshFailure = false

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
        hasNotifiedRefreshFailure = false
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
                await notifyRefreshFailed()
                throw NetworkError.unauthorized
            }

            // 재시도 호출은 do 블록 밖에 둔다.
            // 안에 두면 재귀 호출이 한도 초과로 던진 unauthorized까지 아래 catch에 걸려
            // 세션 종료 처리 경로를 한 번 더 타게 된다.
            //
            // 세션 종료(토큰 삭제 + 통지)는 refresh token이 없거나 서버가 401로 거절한 경우만이다.
            // 5xx 같은 일시적 실패에서 토큰을 지우면 서버 장애 한 번에 전원이 로그아웃된다.
            do {
                _ = try await refreshToken()
            } catch NetworkError.unauthorized, TokenRefreshError.serverError(statusCode: 401) {
                await notifyRefreshFailed()
                throw NetworkError.unauthorized
            } catch TokenRefreshError.serverError(let statusCode) {
                // 일반 요청의 서버 오류와 같은 경로로 흘려 상태 코드 기반 문구·재시도 판단을 받게 한다
                throw NetworkError.httpError(statusCode: statusCode, data: Data())
            } catch TokenRefreshError.invalidResponse {
                throw NetworkError.invalidResponse
            }

            return try await performRequest(urlRequest, retryCount: retryCount + 1)
        }

        // 성공 응답 확인
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        return (data, httpResponse)
    }

    /// 세션 종료를 상위에 통지한다. 새 토큰을 확보하기 전까지 1회만 나간다.
    ///
    /// 갱신 Task는 하나로 합쳐지지만 그 실패는 대기하던 요청 전원에게 전달된다.
    /// 각자 콜백을 부르면 동시 401 N건에 통지가 N번 나가므로, 여기서 한 번으로 접는다.
    /// 재귀 재시도와 재시도 한도 소진 경로도 같은 이유로 이 함수를 거친다.
    ///
    /// 통지 전에 저장된 토큰을 지운다. 화면 상태만 로그아웃되고 토큰이 남으면,
    /// 다음 실행 때 자동 로그인 → 401 → 다시 로그인 화면으로 튕긴다.
    private func notifyRefreshFailed() async {
        guard !hasNotifiedRefreshFailure else { return }
        // await 전에 플래그를 세워, 삭제를 기다리는 동안 합류한 다른 요청이 중복 통지하지 않게 한다
        hasNotifiedRefreshFailure = true
        try? await tokenStore.clear()
        onRefreshFailed?()
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

            // logout()은 이 Task를 cancel한 뒤 tokenStore.clear()를 기다린다.
            // 취소를 관측하는 지점이 session.data(for:) 안뿐이면, 응답이 이미 도착한 뒤 온 logout은
            // clear 다음에 아래 save를 실행시켜 Keychain에 유효 토큰을 되살린다(다음 실행 시 자동 로그인).
            // 저장 직전에 한 번 더 확인해 그 문을 닫는다.
            try Task.checkCancellation()

            try await tokenStore.save(
                accessToken: tokenPair.accessToken,
                refreshToken: tokenPair.refreshToken
            )
            // 세션이 되살아났으므로 다음 만료 때 다시 통지할 수 있게 되돌린다.
            hasNotifiedRefreshFailure = false

            return tokenPair
        }

        refreshTask = task
        return try await task.value
    }
}
