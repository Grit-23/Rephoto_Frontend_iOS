//
//  FetchUserUseCase.swift
//  UserDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import UserDomainInterface

public final class FetchUserUseCase: FetchUserUseCaseProtocol {
    private let repository: any UserRepositoryProtocol

    public init(repository: any UserRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> UserInfo {
        try await repository.fetchUser()
    }
}
