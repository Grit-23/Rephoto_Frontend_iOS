//
//  SessionStore.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/2/26.
//

import SwiftUI

/// 앱 전역 인증/세션 상태를 소유한다.
/// 인증 동작(로그인/로그아웃/복원)을 담당하며 실패는 throw로 알린다.
/// 로딩/에러 같은 화면 표현 상태는 각 화면의 ViewModel이 가진다.
@Observable
@MainActor
final class SessionStore {
    private let provider: UserUseCaseProviderProtocol

    private(set) var isLoggedIn = false
    private(set) var userInfo: UserInfo?
    private(set) var name: String = "리포토"

    init(provider: UserUseCaseProviderProtocol) {
        self.provider = provider

        provider.setOnRefreshFailed { [weak self] in
            Task { @MainActor in
                self?.forceLogout()
            }
        }
    }

    /// 앱 시작 시 저장된 토큰으로 세션 복원 (자동 로그인).
    func restore() async {
        guard await provider.hasTokens() else { return }
        isLoggedIn = true
        await refreshUser()
    }

    /// 자격 증명으로 로그인. 실패 시 throw.
    func login(id: String, password: String) async throws {
        try await provider.login().execute(loginId: id, password: password)
        isLoggedIn = true
        await refreshUser()
    }

    func logout() async {
        try? await provider.logout().execute()
        forceLogout()
    }

    /// 토큰 리프레시 실패 등으로 인한 강제 로그아웃 (로컬 상태만 정리).
    func forceLogout() {
        userInfo = nil
        isLoggedIn = false
    }

    private func refreshUser() async {
        guard let info = try? await provider.fetchUser().execute() else { return }
        userInfo = info
        name = info.name
    }
}
