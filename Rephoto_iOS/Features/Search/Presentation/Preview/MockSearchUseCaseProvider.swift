//
//  MockSearchUseCaseProvider.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

#if DEBUG
import Foundation

final class MockSearchUseCaseProvider: SearchUseCaseProviderProtocol {
    func getAlbums() -> GetAlbumsUseCaseProtocol {
        MockGetAlbumsUseCase()
    }

    func getAlbumPhotos() -> GetAlbumPhotosUseCaseProtocol {
        MockGetAlbumPhotosUseCase()
    }

    func searchPhotos() -> SearchUseCaseProtocol {
        MockSearchUseCase()
    }
}

// MARK: - Mock UseCases

private struct MockGetAlbumsUseCase: GetAlbumsUseCaseProtocol {
    func execute() async throws -> [Album] {
        [
            Album(tagId: 1, tagName: "바다"),
            Album(tagId: 2, tagName: "산"),
            Album(tagId: 3, tagName: "카페"),
            Album(tagId: 4, tagName: "여행"),
        ]
    }
}

private struct MockGetAlbumPhotosUseCase: GetAlbumPhotosUseCaseProtocol {
    func execute(tagId: Int) async throws -> [Photo] {
        (1...6).map { i in
            Photo(
                photoId: tagId * 100 + i,
                imageUrl: URL(string: "https://picsum.photos/seed/\(tagId)-\(i)/400")!,
                latitude: 37.5665,
                longitude: 126.9780,
                createdAt: Date(),
                fileName: "photo_\(i).jpg",
                tags: ["mock"],
                isSensitive: false
            )
        }
    }
}

private struct MockSearchUseCase: SearchUseCaseProtocol {
    func execute(query: String) async throws -> [SearchResult] {
        (1...4).map { i in
            SearchResult(
                imageUrl: URL(string: "https://picsum.photos/seed/search-\(i)/400")!,
                photoId: i
            )
        }
    }
}
#endif
