//
//  GetPhotosUseCaseTests.swift
//  PhotoDomainTests
//
//  Created by Doyeon Kim on 11/4/26.
//

import Foundation
import Testing
import PhotoDomainInterface
import PhotoDomainTesting
@testable import PhotoDomain

/// UseCase가 Repository에 위임하는지와, mockolo가 만든 Mock이 동작하는지를 함께 본다.
@Suite("GetPhotosUseCase")
struct GetPhotosUseCaseTests {

    @Test("Repository의 목록을 그대로 반환한다")
    func returnsRepositoryPhotos() async throws {
        let repository = PhotoRepositoryProtocolMock()
        let expected = [
            Photo(
                photoId: 1,
                imageUrl: URL(string: "https://cdn.test/1.jpg")!,
                latitude: 37.5,
                longitude: 126.9,
                createdAt: Date(timeIntervalSince1970: 0),
                fileName: "1.jpg",
                tags: [],
                isSensitive: false
            ),
        ]
        repository.getAllPhotosHandler = { expected }
        let sut = GetPhotosUseCase(repository: repository)

        let photos = try await sut.execute()

        #expect(repository.getAllPhotosCallCount == 1)
        #expect(photos == expected)
    }
}
