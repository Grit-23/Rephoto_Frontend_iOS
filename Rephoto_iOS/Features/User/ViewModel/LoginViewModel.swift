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
    
    private let provider = MoyaProvider<UserAPITarget>()
    
    // MARK: - Actions
    func login() {
        // 간단한 유효성 검사
        guard !loginId.isEmpty, !password.isEmpty else {
            errorMessage = "아이디와 비밀번호를 입력해주세요."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        provider.request(.login(loginId: loginId, password: password)) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let response):
                // 응답 상태 코드 로그
                print("Status Code:", response.statusCode)
                
                // 응답 Body 로그
                if let jsonString = String(data: response.data, encoding: .utf8) {
                    print("Response JSON:", jsonString)
                }
                
                // 상태 코드 검사
                guard (200..<300).contains(response.statusCode) else {
                    self.errorMessage = "서버 오류: \(response.statusCode)"
                    return
                }
                
                do {
                    let dto = try JSONDecoder().decode(LoginResponseDto.self, from: response.data)
                    
                    // 토큰 저장
                    UserDefaults.standard.set(dto.accessToken, forKey: "accessToken")
                    UserDefaults.standard.set(dto.refreshToken, forKey: "refreshToken")
                    
                    // 로그인 성공 처리
                    self.isLoggedIn = true
                } catch {
                    self.errorMessage = "로그인 응답을 해석할 수 없습니다. (\(error.localizedDescription))"
                }
                
            case .failure(let error):
                self.errorMessage = "로그인 실패: \(error.localizedDescription)"
            }
        }
    }
    
    func logout() {
        isLoading = true
        errorMessage = nil
        
        provider.request(.logout) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success:
                self.userInfo = nil
                self.isLoggedIn = false
            case .failure(let error):
                self.errorMessage = "로그아웃 실패: \(error.localizedDescription)"
            }
        }
    }
}
