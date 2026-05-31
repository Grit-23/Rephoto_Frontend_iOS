//
//  LoginViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import SwiftUI

@Observable
@MainActor
final class LoginViewModel {
    let provider: UserUseCaseProviderProtocol

    var loginId: String = ""
    var password: String = ""
    private(set) var isLoading = false
    var errorMessage: String?
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

    func onAppear() async {
        if await provider.hasTokens() {
            isLoggedIn = true
            await fetchUser()
        }
    }

    func login() async {
        guard !loginId.isEmpty, !password.isEmpty else {
            errorMessage = "아이디와 비밀번호를 입력해주세요."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await provider.login().execute(loginId: loginId, password: password)
            isLoggedIn = true
            await fetchUser()
        } catch {
            errorMessage = "로그인 실패: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func fetchUser() async {
        isLoading = true
        errorMessage = nil

        do {
            let info = try await provider.fetchUser().execute()
            userInfo = info
            name = info.name
        } catch {
            errorMessage = "내 정보 조회 실패: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func logout() async {
        isLoading = true
        errorMessage = nil

        do {
            try await provider.logout().execute()
        } catch {
            errorMessage = "로그아웃 실패: \(error.localizedDescription)"
        }

        forceLogout()
        isLoading = false
    }

    func forceLogout() {
        userInfo = nil
        isLoggedIn = false
    }
}
