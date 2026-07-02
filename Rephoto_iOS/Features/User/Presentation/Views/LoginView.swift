//
//  LoginView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import SwiftUI

struct LoginView: View {
    @Bindable var loginVM: LoginViewModel

    var body: some View {
        ZStack {
            Color.base.ignoresSafeArea(edges: .all)
            
            VStack(alignment: .leading, spacing: 60) {
                header
                textField
                buttons
            }
            .padding(.horizontal)
            .alert("오류", isPresented: $loginVM.isShowingError, presenting: loginVM.errorMessage) { _ in
                Button("확인", role: .cancel) { }
            } message: { message in
                Text(message)
            }
        }
        .task { await loginVM.onAppear() }
    }

    // MARK: - Title

    private var header: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 28)
                .foregroundStyle(
                    Gradient(colors: [.lightGreen, .deepGreen])
                )
                .frame(height: 240)
            VStack(alignment: .leading, spacing: 12) {
                Text("Rephoto")
                    .font(.system(size: 40, weight: .bold))
                Text("사진을 기억으로 묶다")
                    .font(.system(size: 16))
            }
            .padding(.leading, 20)
            .foregroundStyle(.white)
        }
    }

    // MARK: - TextFields

    private var textField: some View {
        VStack(spacing: 40) {
            LoginTextField(
                title: "이메일",
                image: "envelope",
                text: $loginVM.loginId,
                placeholder: "이메일을 입력하세요"
            )
            
            LoginTextField(
                title: "비밀번호",
                image: "lock",
                text: $loginVM.password,
                placeholder: "비밀번호를 입력하세요",
                isSecure: true
            )
        }
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: 16) {
            CTAButton(title: "로그인", isLoading: loginVM.isLoading) {
                Task { await loginVM.login() }
            }
            NavigationLink {
                
            } label: {
                Text("회원가입")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .disabled(true)
        }
    }
}

#if DEBUG
#Preview("Login") {
    LoginView(loginVM: LoginViewModel(provider: MockUserUseCaseProvider()))
}
#endif
