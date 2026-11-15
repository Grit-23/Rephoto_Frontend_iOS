//
//  SessionStore.swift
//  UserFeature
//
//  Created by 김도연 on 7/2/26.
//

import SwiftUI
import UserDomainInterface

/// 앱 전역 인증/세션 상태를 소유한다.
/// 인증 동작(로그인/로그아웃/복원)을 담당하며 실패는 throw로 알린다.
/// 로딩/에러 같은 화면 표현 상태는 각 화면의 ViewModel이 가진다.
@Observable
public final class SessionStore {
    private let provider: any UserUseCaseProviderProtocol

    public private(set) var isLoggedIn = false
    public private(set) var userInfo: UserInfo?

    /// 사용자 정보가 없으면(조회 전 · 조회 실패 · 로그아웃) 기본 이름을 쓴다.
    public var name: String { userInfo?.name ?? "리포토" }

    public init(provider: any UserUseCaseProviderProtocol) {
        self.provider = provider
    }

    /// 앱 시작 시 한 번 호출한다. 갱신 실패 핸들러 등록을 마친 뒤 저장된 토큰으로 세션을 복원한다.
    public func restore() async {
        await provider.setOnRefreshFailed { [weak self] in
            Task { @MainActor in
                self?.forceLogout()
            }
        }
        guard await provider.hasTokens() else { return }
        isLoggedIn = true
        await refreshUser()
    }

    /// 자격 증명으로 로그인. 실패 시 throw.
    public func login(id: String, password: String) async throws {
        try await provider.makeLoginUseCase().execute(loginId: id, password: password)
        isLoggedIn = true
        await refreshUser()
    }

    public func logout() async {
        try? await provider.makeLogoutUseCase().execute()
        forceLogout()
    }

    /// 토큰 리프레시 실패 등으로 인한 강제 로그아웃 (화면 상태만 정리).
    /// 저장된 토큰은 `NetworkClient`가 이 통지를 보내기 전에 이미 지운다.
    public func forceLogout() {
        userInfo = nil
        isLoggedIn = false
    }

    private func refreshUser() async {
        guard let info = try? await provider.makeFetchUserUseCase().execute() else { return }
        userInfo = info
    }
}
