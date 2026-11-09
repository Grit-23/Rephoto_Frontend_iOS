//
//  GetAlbumPhotosUseCaseTests.swift
//  AlbumDomainTests
//
//  Created by Doyeon Kim on 11/9/26.
//

import Foundation
import Testing
import PhotoDomainInterface
import PhotoDomainTesting
@testable import AlbumDomain

/// 앨범 사진은 Album Repository가 아니라 PhotoDomain의 Repository로 조회한다.
@Suite("GetAlbumPhotosUseCase")
struct GetAlbumPhotosUseCaseTests {

    @Test("tagId를 사진 Repository에 그대로 넘기고 결과를 반환한다")
    func forwardsTagIdToPhotoRepository() async throws {
        let repository = PhotoRepositoryProtocolMock()
        let expected = [
            Photo(
                photoId: 1,
                imageUrl: URL(string: "https://cdn.test/1.jpg")!,
                latitude: 37.5,
                longitude: 126.9,
                createdAt: Date(timeIntervalSince1970: 0),
                fileName: "1.jpg",
                tags: ["커피"],
                isSensitive: false
            ),
        ]
        repository.getPhotosHandler = { _ in expected }
        let sut = GetAlbumPhotosUseCase(repository: repository)

        let photos = try await sut.execute(tagId: 7)

        #expect(repository.getPhotosCallCount == 1)
        #expect(repository.getPhotosArgValues == [7])
        #expect(photos == expected)
        #expect(repository.getAllPhotosCallCount == 0)
    }
}
