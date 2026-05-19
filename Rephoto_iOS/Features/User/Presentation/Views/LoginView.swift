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
        NavigationStack {
            VStack(alignment: .leading, spacing: 60) {
                title
                Spacer()
                textField
                buttons
                Spacer()
                kakaoLogin
            }
            .padding(.horizontal, 20)
            .alert(isPresented: .constant(loginVM.errorMessage != nil)) {
                Alert(
                    title: Text("오류"),
                    message: Text(loginVM.errorMessage ?? ""),
                    dismissButton: .default(Text("확인")) {
                        loginVM.errorMessage = nil
                    }
                )
            }
        }
        .task { await loginVM.onAppear() }
    }

    // MARK: - Title

    private var title: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("안녕하세요.\n리포토입니다.")
                .font(.system(size: 28, weight: .bold))

            Text("회원 서비스 이용을 위해 로그인 해주세요")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.top, 80)
    }

    // MARK: - TextFields

    private var textField: some View {
        VStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("아이디", text: $loginVM.loginId)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                Divider()
            }
            VStack(alignment: .leading, spacing: 8) {
                SecureField("비밀번호", text: $loginVM.password)
                    .textInputAutocapitalization(.never)
                Divider()
            }
        }
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: 16) {
            Button {
                Task { await loginVM.login() }
            } label: {
                Text("로그인하기")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Capsule()
                            .tint(.green)
                    )
            }
            NavigationLink {
                // 회원가입 화면
            } label: {
                Text("회원가입")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .underline()
            }
        }
    }

    // MARK: - Kakao Login

    private var kakaoLogin: some View {
        Button {
            // TODO: 카카오 로그인
        } label: {
            Text("카카오로 로그인")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .leading) {
                    Image(.kakao)
                        .padding(.leading, 4)
                }
        }
        .frame(height: 48)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(.yellow)
        .foregroundStyle(.black)
    }
}

#if DEBUG
#Preview("Login") {
    LoginView(loginVM: LoginViewModel(provider: MockUserUseCaseProvider()))
}
#endif
