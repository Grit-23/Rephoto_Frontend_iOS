//
//  LoginUseCaseTests.swift
//  UserDomainTests
//
//  Created by Doyeon Kim on 11/15/26.
//

import Foundation
import Testing
import UserDomainInterface
import UserDomainTesting
@testable import UserDomain

@Suite("LoginUseCase")
struct LoginUseCaseTests {

    @Test("자격증명을 Repository에 그대로 넘긴다")
    func forwardsCredentialsToRepository() async throws {
        let repository = UserRepositoryProtocolMock()
        repository.loginHandler = { _, _ in }
        let sut = LoginUseCase(repository: repository)

        try await sut.execute(loginId: "dodle", password: "secret!")

        let arguments = try #require(repository.loginArgValues.first)
        #expect(repository.loginCallCount == 1)
        #expect(arguments.loginId == "dodle")
        #expect(arguments.password == "secret!")
    }

    @Test("Repository의 실패를 그대로 던진다")
    func rethrowsRepositoryError() async throws {
        let repository = UserRepositoryProtocolMock()
        repository.loginHandler = { _, _ in throw URLError(.userAuthenticationRequired) }
        let sut = LoginUseCase(repository: repository)

        await #expect(throws: URLError.self) {
            try await sut.execute(loginId: "dodle", password: "wrong")
        }
    }
}
