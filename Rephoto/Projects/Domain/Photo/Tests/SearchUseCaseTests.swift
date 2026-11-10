//
//  SearchUseCaseTests.swift
//  PhotoDomainTests
//
//  Created by Doyeon Kim on 11/9/26.
//

import Foundation
import Testing
import PhotoDomainInterface
import PhotoDomainTesting
@testable import PhotoDomain

@Suite("SearchUseCase")
struct SearchUseCaseTests {

    @Test("질의를 Repository에 그대로 넘기고 결과를 반환한다")
    func forwardsQueryToRepository() async throws {
        let repository = SearchRepositoryProtocolMock()
        let expected = [SearchResult(imageUrl: URL(string: "https://cdn.test/1.jpg")!, photoId: 1)]
        repository.searchHandler = { _ in expected }
        let sut = SearchUseCase(repository: repository)

        let results = try await sut.execute(query: "바다")

        #expect(repository.searchCallCount == 1)
        #expect(repository.searchArgValues == ["바다"])
        #expect(results == expected)
    }
}
