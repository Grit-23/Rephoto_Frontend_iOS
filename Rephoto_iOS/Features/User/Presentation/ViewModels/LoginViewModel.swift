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

    /// 로그인 화면은 입력 폼이라 전역 Alert 대신 화면 안에서 에러를 안고 간다.
    /// 사용자가 값을 고쳐 바로 다시 시도할 수 있어야 하기 때문이다.
    var error: AppError?

    var isShowingError: Bool {
        get { error != nil }
        set { if !newValue { error = nil } }
    }

    /// Alert 본문에 쓰는 사용자용 문구.
    /// 표시 시점에 해석되도록 `LocalizedStringResource`로 넘긴다.
    var errorMessage: LocalizedStringResource? {
        error?.userMessage
    }

    init(session: SessionStore) {
        self.session = session
    }

    func login() async {
        guard !loginId.isEmpty, !password.isEmpty else {
            error = .domain(.emptyCredentials)
            return
        }

        isLoading = true
        error = nil

        do {
            try await session.login(id: loginId, password: password)
        } catch let caught {
            error = AppError.from(caught)
        }

        isLoading = false
    }
}
