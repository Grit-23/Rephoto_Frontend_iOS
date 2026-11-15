//
//  LoginUseCase.swift
//  UserDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import UserDomainInterface

public final class LoginUseCase: LoginUseCaseProtocol {
    private let repository: any UserRepositoryProtocol

    public init(repository: any UserRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(loginId: String, password: String) async throws {
        try await repository.login(loginId: loginId, password: password)
    }
}
