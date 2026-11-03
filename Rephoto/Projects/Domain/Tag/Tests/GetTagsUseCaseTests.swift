//
//  GetTagsUseCaseTests.swift
//  TagDomainTests
//
//  Created by Doyeon Kim on 11/4/26.
//

import Testing
import TagDomainInterface
import TagDomainTesting
@testable import TagDomain

/// UseCase가 Repository에 인자를 그대로 위임하는지와, mockolo가 만든 Mock이 동작하는지를 함께 본다.
@Suite("GetTagsUseCase")
struct GetTagsUseCaseTests {

    @Test("photoId를 Repository에 그대로 넘기고 결과를 반환한다")
    func forwardsPhotoIdToRepository() async throws {
        let repository = TagRepositoryProtocolMock()
        let expected = [PhotoTag(photoTagId: 10, tagId: 1, tagName: "바다", photoId: 7)]
        repository.getTagsHandler = { _ in expected }
        let sut = GetTagsUseCase(repository: repository)

        let tags = try await sut.execute(photoId: 7)

        #expect(repository.getTagsCallCount == 1)
        #expect(repository.getTagsArgValues == [7])
        #expect(tags.map(\.id) == expected.map(\.id))
    }
}
