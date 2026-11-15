//
//  LogoutUseCaseTests.swift
//  UserDomainTests
//
//  Created by Doyeon Kim on 11/15/26.
//

import Foundation
import Testing
import UserDomainInterface
import UserDomainTesting
@testable import UserDomain

@Suite("LogoutUseCase")
struct LogoutUseCaseTests {

    @Test("Repository의 로그아웃을 한 번 호출한다")
    func callsRepositoryLogout() async throws {
        let repository = UserRepositoryProtocolMock()
        repository.logoutHandler = {}
        let sut = LogoutUseCase(repository: repository)

        try await sut.execute()

        #expect(repository.logoutCallCount == 1)
    }
}
