//
//  GetAlbumsUseCaseTests.swift
//  AlbumDomainTests
//
//  Created by Doyeon Kim on 11/9/26.
//

import Foundation
import Testing
import AlbumDomainInterface
import AlbumDomainTesting
@testable import AlbumDomain

@Suite("GetAlbumsUseCase")
struct GetAlbumsUseCaseTests {

    @Test("Repository의 앨범 목록을 그대로 반환한다")
    func returnsRepositoryAlbums() async throws {
        let repository = AlbumRepositoryProtocolMock()
        let expected = [Album(tagId: 1, tagName: "커피", coverImageUrl: nil, photoCount: 3)]
        repository.getAlbumsHandler = { expected }
        let sut = GetAlbumsUseCase(repository: repository)

        let albums = try await sut.execute()

        #expect(repository.getAlbumsCallCount == 1)
        #expect(albums == expected)
    }
}
