//
//  FetchUserUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

final class FetchUserUseCase: FetchUserUseCaseProtocol {
    private let repository: UserRepositoryProtocol

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> UserInfo {
        try await repository.fetchUser()
    }
}
