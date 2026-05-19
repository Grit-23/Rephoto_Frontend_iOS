//
//  LoginUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

final class LoginUseCase: LoginUseCaseProtocol {
    private let repository: UserRepositoryProtocol

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute(loginId: String, password: String) async throws {
        try await repository.login(loginId: loginId, password: password)
    }
}
