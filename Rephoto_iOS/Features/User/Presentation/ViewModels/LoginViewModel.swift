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
    private let session: SessionStore

    var loginId: String = ""
    var password: String = ""
    private(set) var isLoading = false
    var errorMessage: String?
    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    init(session: SessionStore) {
        self.session = session
    }

    func login() async {
        guard !loginId.isEmpty, !password.isEmpty else {
            errorMessage = "아이디와 비밀번호를 입력해주세요."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await session.login(id: loginId, password: password)
        } catch {
            errorMessage = "로그인 실패: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
