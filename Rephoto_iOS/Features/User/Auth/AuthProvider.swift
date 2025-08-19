//
//  AuthProvider.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/18/25.
//

import Moya
import Foundation

struct RefreshResponseDto: Decodable {
    let accessToken: String
    let refreshToken: String
}

final class AuthedProvider {
    private let tokenStore: TokenStore
    private let provider: MoyaProvider<UserAPITarget>

    private let lock = NSLock()
    private var isRefreshing = false

    private struct Pending {
        let target: UserAPITarget
        let progress: ProgressBlock?
        let completion: (Result<Response, MoyaError>) -> Void
    }
    private var queue: [Pending] = []

    /// 리프레시 실패 시 처리(예: 강제 로그아웃)
    var onRefreshFailed: (() -> Void)?

    init(tokenStore: TokenStore = .shared) {
        self.tokenStore = tokenStore
        self.provider = MoyaProvider<UserAPITarget>(plugins: [AuthPlugin(tokenStore: tokenStore)])
    }

    func request(_ target: UserAPITarget,
                 callbackQueue: DispatchQueue? = nil,
                 progress: ProgressBlock? = nil,
                 completion: @escaping (Result<Response, MoyaError>) -> Void) {

        provider.request(target, callbackQueue: callbackQueue, progress: progress) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let response) where self.shouldRefresh(response: response, target: target):
                self.enqueueAndRefresh(target: target, progress: progress, completion: completion)

            default:
                completion(result)
            }
        }
    }

    private func shouldRefresh(response: Response, target: UserAPITarget) -> Bool {
        // 서버 규약에 따라 401/403/419 등으로 조정
        let isUnauthorized = response.statusCode == 401
        // 리프레시 요청 자체가 실패한 401이면 더 시도하지 않음
        let isRefreshCall = {
            if case .refreshToken = target { return true }
            return false
        }()
        let isLoginCall = {
            if case .login = target { return true }
            return false
        }()
        return isUnauthorized && !isRefreshCall && !isLoginCall
    }

    private func enqueueAndRefresh(target: UserAPITarget,
                                   progress: ProgressBlock?,
                                   completion: @escaping (Result<Response, MoyaError>) -> Void) {
        lock.lock()
        queue.append(Pending(target: target, progress: progress, completion: completion))
        let shouldStartRefresh = !isRefreshing
        if shouldStartRefresh { isRefreshing = true }
        lock.unlock()

        guard shouldStartRefresh else { return } // 이미 다른 스레드가 리프레시 중

        performRefresh { [weak self] success in
            guard let self else { return }

            self.lock.lock()
            let pendings = self.queue
            self.queue.removeAll()
            self.isRefreshing = false
            self.lock.unlock()

            if success {
                // 새 토큰으로 모두 재시도
                pendings.forEach { pending in
                    self.provider.request(pending.target, progress: pending.progress, completion: pending.completion)
                }
            } else {
                // 전부 실패 처리 + 상위에 알림
                let err = MoyaError.underlying(NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "토큰 갱신 실패"]), nil)
                pendings.forEach { $0.completion(.failure(err)) }
                self.onRefreshFailed?()
            }
        }
    }

    private func performRefresh(completion: @escaping (Bool) -> Void) {
        guard let refresh = tokenStore.refreshToken, !refresh.isEmpty else {
            completion(false); return
        }

        // 주의: AuthPlugin이 refreshToken 호출엔 Authorization을 붙이지 않게 해놨음
        provider.request(.refreshToken(refreshToken: refresh)) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let res):
                guard (200..<300).contains(res.statusCode) else { completion(false); return }
                do {
                    let dto = try JSONDecoder().decode(RefreshResponseDto.self, from: res.data)
                    self.tokenStore.save(TokenPair(accessToken: dto.accessToken, refreshToken: dto.refreshToken))
                    completion(true)
                } catch {
                    completion(false)
                }
            case .failure:
                completion(false)
            }
        }
    }
}
