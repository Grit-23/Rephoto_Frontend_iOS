//
//  LogoutUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

final class LogoutUseCase: LogoutUseCaseProtocol {
    private let repository: UserRepositoryProtocol

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.logout()
    }
}
