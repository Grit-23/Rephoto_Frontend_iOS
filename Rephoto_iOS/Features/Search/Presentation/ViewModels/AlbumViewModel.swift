//
//  AlbumViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

@Observable
final class AlbumViewModel {
    let provider: SearchUseCaseProviderProtocol

    /// 앨범 카드에 표시할 대표 썸네일과 사진 수
    struct AlbumPreview {
        let thumbnailUrl: URL?
        let photoCount: Int
    }

    private(set) var albums: [Album] = []
    private(set) var albumPreviews: [Int: AlbumPreview] = [:]
    private(set) var albumPhotos: [Photo] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(provider: SearchUseCaseProviderProtocol) {
        self.provider = provider
    }

    @MainActor
    func fetchAlbums() async {
        isLoading = true
        errorMessage = nil
        do {
            albums = try await provider.getAlbums().execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false

        // 앨범 목록을 먼저 노출한 뒤, 카드용 대표 사진/장수는 뒤이어 채운다
        for album in albums {
            guard let photos = try? await provider.getAlbumPhotos().execute(tagId: album.tagId) else { continue }
            albumPreviews[album.tagId] = AlbumPreview(
                thumbnailUrl: photos.first?.imageUrl,
                photoCount: photos.count
            )
        }
    }

    @MainActor
    func fetchAlbumPhotos(tagId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            albumPhotos = try await provider.getAlbumPhotos().execute(tagId: tagId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

