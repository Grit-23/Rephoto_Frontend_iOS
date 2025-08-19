//
//  LoginViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/14/25.
//

import SwiftUI
import Combine
import Moya

final class LoginViewModel: ObservableObject {
    @Published var loginId: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isLoggedIn: Bool = false
    @Published var userInfo: UserInfoResponseDto?
    @State var name: String = ""

    /// 로그인(무인증) 전용
    private let plainProvider = MoyaProvider<UserAPITarget>()
    /// 인증요청(만료 시 자동 리프레시 & 재시도)
    private let authedProvider = AuthedProvider()

    init() {
        // 앱 시작 시 토큰이 남아있다면 로그인 유지
        if TokenStore.shared.hasTokens {
            isLoggedIn = true
            fetchUser()
        }

        // 리프레시 실패(401/만료 등) 시 강제 로그아웃
        authedProvider.onRefreshFailed = { [weak self] in
            DispatchQueue.main.async {
                self?.forceLogout()
            }
        }
        
        fetchUser()
    }

    // MARK: - Actions
    func login() {
        guard !loginId.isEmpty, !password.isEmpty else {
            errorMessage = "아이디와 비밀번호를 입력해주세요."
            return
        }

        isLoading = true
        errorMessage = nil

        plainProvider.request(.login(loginId: loginId, password: password)) { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let response):
                // 상태 코드 검사
                guard (200..<300).contains(response.statusCode) else {
                    self.errorMessage = "서버 오류: \(response.statusCode)"
                    return
                }

                do {
                    let dto = try JSONDecoder().decode(LoginResponseDto.self, from: response.data)

                    // ⬇️ 토큰 저장 (UserDefaults 대신 TokenStore 사용)
                    TokenStore.shared.save(TokenPair(accessToken: dto.accessToken, refreshToken: dto.refreshToken))

                    // 로그인 성공 처리
                    self.isLoggedIn = true
                    self.fetchUser() // 선택: 로그인 직후 내 정보 받아오기
                } catch {
                    self.errorMessage = "로그인 응답을 해석할 수 없습니다. (\(error.localizedDescription))"
                }

            case .failure(let error):
                self.errorMessage = "로그인 실패: \(error.localizedDescription)"
            }
        }
    }

    /// 토큰이 필요한 API는 전부 authedProvider로 호출
    func fetchUser() {
        isLoading = true
        errorMessage = nil

        authedProvider.request(.getUser) { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let res):
                guard (200..<300).contains(res.statusCode) else {
                    self.errorMessage = "내 정보 조회 실패: \(res.statusCode)"
                    return
                }
                do {
                    let dto = try JSONDecoder().decode(UserInfoResponseDto.self, from: res.data)
                    self.userInfo = dto
                    self.name = dto.name
                } catch {
                    self.errorMessage = "프로필 파싱 실패: \(error.localizedDescription)"
                }
            case .failure(let err):
                self.errorMessage = "내 정보 조회 실패: \(err.localizedDescription)"
            }
        }
    }

    func logout() {
        isLoading = true
        errorMessage = nil

        authedProvider.request(.logout) { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let res):
                // 2xx가 아니더라도 서버 정책상 성공 처리일 수 있음. 필요 시 분기 조정.
                if !(200..<300).contains(res.statusCode) {
                    // 서버가 204/200 이외 코드를 줄 수 있으니 로깅만 하고 계속 진행할 수도 있음.
                    print("Logout status: \(res.statusCode)")
                }
                self.forceLogout()

            case .failure(let error):
                // 네트워크 에러 등으로 로그아웃 API 실패해도 로컬 토큰은 지워주는 편이 UX상 좋음.
                self.errorMessage = "로그아웃 실패: \(error.localizedDescription)"
                self.forceLogout()
            }
        }
    }

    // MARK: - Helpers
    private func forceLogout() {
        TokenStore.shared.clear()
        userInfo = nil
        isLoggedIn = false
    }
}
