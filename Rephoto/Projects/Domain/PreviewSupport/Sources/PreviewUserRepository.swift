//
//  PreviewUserRepository.swift
//  PreviewSupport
//
//  Created by Doyeon Kim on 11/15/26.
//

import Foundation
import Synchronization
import RephotoFoundation
import UserDomainInterface

/// 로그인 상태를 메모리에 들고 있는 Repository. 어떤 자격증명이든 로그인에 성공한다.
public final class PreviewUserRepository: UserRepositoryProtocol, Sendable {
    private struct State {
        var isLoggedIn: Bool
        var onRefreshFailed: (@Sendable () -> Void)?
    }

    private let state: Mutex<State>
    private let userInfo: UserInfo

    public init(
        isLoggedIn: Bool = false,
        userInfo: UserInfo = UserInfo(userId: 1, loginId: 1, name: "리포토")
    ) {
        self.state = Mutex(State(isLoggedIn: isLoggedIn))
        self.userInfo = userInfo
    }

    public func login(loginId: String, password: String) async throws {
        state.withLock { $0.isLoggedIn = true }
    }

    public func fetchUser() async throws -> UserInfo {
        guard state.withLock({ $0.isLoggedIn }) else { throw NetworkError.unauthorized }
        return userInfo
    }

    public func logout() async throws {
        state.withLock { $0.isLoggedIn = false }
    }

    public func hasTokens() async -> Bool {
        state.withLock { $0.isLoggedIn }
    }

    public func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) {
        state.withLock { $0.onRefreshFailed = handler }
    }

    /// 토큰 갱신 실패를 흉내 낸다. 서버 없이 강제 로그아웃 흐름을 확인할 때 쓴다.
    public func failRefresh() {
        let handler = state.withLock { state in
            state.isLoggedIn = false
            return state.onRefreshFailed
        }
        handler?()
    }
}
