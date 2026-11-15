//
//  FetchUserUseCaseTests.swift
//  UserDomainTests
//
//  Created by Doyeon Kim on 11/15/26.
//

import Foundation
import Testing
import UserDomainInterface
import UserDomainTesting
@testable import UserDomain

@Suite("FetchUserUseCase")
struct FetchUserUseCaseTests {

    @Test("Repository의 사용자 정보를 그대로 반환한다")
    func returnsRepositoryUser() async throws {
        let repository = UserRepositoryProtocolMock()
        let expected = UserInfo(userId: 1, loginId: 7, name: "도연")
        repository.fetchUserHandler = { expected }
        let sut = FetchUserUseCase(repository: repository)

        let user = try await sut.execute()

        #expect(repository.fetchUserCallCount == 1)
        #expect(user == expected)
    }
}
