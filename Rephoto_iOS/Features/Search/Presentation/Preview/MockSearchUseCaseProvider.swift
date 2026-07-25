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

// MARK: - MockAlbumFixtures

/// 홈 데모 사진(MockPhotoFixtures)을 태그 테마별로 묶은 앨범 구성.
/// tagId는 배열 순서 기반 index + 1
private enum MockAlbumFixtures {
    static let groups: [(tagName: String, fileNames: [String])] = [
        ("커피", ["IMG_0813.jpeg", "IMG_0356.jpeg", "IMG_0673.jpeg"]),
        ("남산", ["IMG_0275.jpeg", "IMG_0689.jpeg", "IMG_2015.JPG"]),
        ("봄", ["IMG_9898.jpeg", "IMG_0871.jpeg"]),
        ("바다", ["IMG_9563.jpeg"]),
        ("한강", ["IMG_0099.jpeg"]),
        ("고양이", ["IMG_8415.JPG"]),
    ]

    /// 파일명 목록을 홈 픽스처의 Photo(동일 photoId)로 변환
    static func photos(fileNames: [String]) -> [Photo] {
        fileNames.compactMap { fileName in
            guard let index = MockPhotoFixtures.entries.firstIndex(where: { $0.fileName == fileName }) else {
                return nil
            }
            return MockPhotoFixtures.photo(at: index)
        }
    }
}

// MARK: - Mock UseCases

private struct MockGetAlbumsUseCase: GetAlbumsUseCaseProtocol {
    func execute() async throws -> [Album] {
        MockAlbumFixtures.groups.enumerated().map { index, group in
            Album(tagId: index + 1, tagName: group.tagName)
        }
    }
}

private struct MockGetAlbumPhotosUseCase: GetAlbumPhotosUseCaseProtocol {
    func execute(tagId: Int) async throws -> [Photo] {
        guard MockAlbumFixtures.groups.indices.contains(tagId - 1) else { return [] }
        return MockAlbumFixtures.photos(fileNames: MockAlbumFixtures.groups[tagId - 1].fileNames)
    }
}

private struct MockSearchUseCase: SearchUseCaseProtocol {
    func execute(query: String) async throws -> [SearchResult] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }

        // 태그/AI 설명에서 검색어 매칭 (민감 사진 제외)
        return MockPhotoFixtures.entries.enumerated().compactMap { index, entry in
            guard !entry.isSensitive else { return nil }
            let matched = entry.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                || entry.description.localizedCaseInsensitiveContains(query)
            guard matched else { return nil }
            return SearchResult(
                imageUrl: MockPhotoFixtures.imageUrl(fileName: entry.fileName),
                photoId: index + 1
            )
        }
    }
}
#endif
