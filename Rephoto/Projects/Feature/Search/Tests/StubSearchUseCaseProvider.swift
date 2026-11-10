//
//  StubSearchUseCaseProvider.swift
//  SearchFeatureTests
//
//  Created by Doyeon Kim on 11/10/26.
//

import Foundation
import AlbumDomainInterface
import AlbumDomainTesting
import PhotoDomainInterface
import PhotoDomainTesting
@testable import SearchFeature

/// mockolo Mock 4개를 들고 있는 Provider. 테스트는 Mock의 Handler를 바꿔 UseCase 응답을 정한다.
final class StubSearchUseCaseProvider: SearchUseCaseProviderProtocol {
    let getAlbums = GetAlbumsUseCaseProtocolMock()
    let getAlbumPhotos = GetAlbumPhotosUseCaseProtocolMock()
    let search = SearchUseCaseProtocolMock()
    let getPhotos = GetPhotosUseCaseProtocolMock()

    func makeGetAlbumsUseCase() -> any GetAlbumsUseCaseProtocol { getAlbums }
    func makeGetAlbumPhotosUseCase() -> any GetAlbumPhotosUseCaseProtocol { getAlbumPhotos }
    func makeSearchUseCase() -> any SearchUseCaseProtocol { search }
    func makeGetPhotosUseCase() -> any GetPhotosUseCaseProtocol { getPhotos }
}

// Mock의 @Sendable Handler 안에서 호출되므로 테스트 모듈 기본 격리(MainActor)를 벗어난다
nonisolated extension Photo {
    static func stub(photoId: Int) -> Photo {
        Photo(
            photoId: photoId,
            imageUrl: URL(string: "https://cdn.test/\(photoId).jpg")!,
            latitude: 37.5,
            longitude: 126.9,
            createdAt: Date(timeIntervalSince1970: 0),
            fileName: "\(photoId).jpg",
            tags: [],
            isSensitive: false
        )
    }
}

nonisolated extension Album {
    static func stub(tagId: Int, name: String = "바다", photoCount: Int = 1) -> Album {
        Album(
            tagId: tagId,
            tagName: name,
            coverImageUrl: URL(string: "https://cdn.test/album-\(tagId).jpg"),
            photoCount: photoCount
        )
    }
}

nonisolated extension SearchResult {
    static func stub(photoId: Int) -> SearchResult {
        SearchResult(imageUrl: URL(string: "https://cdn.test/\(photoId).jpg")!, photoId: photoId)
    }
}
