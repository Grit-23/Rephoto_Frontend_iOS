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

    /// "앨범이 없음"과 "앨범을 못 불러옴"이 섞이지 않도록 Loadable로 상태를 나눈다
    private(set) var albums: Loadable<[Album]> = .idle
    private(set) var albumPhotos: Loadable<[Photo]> = .idle

    init(provider: SearchUseCaseProviderProtocol) {
        self.provider = provider
    }

    @MainActor
    func fetchAlbums() async {
        albums = .loading
        do {
            albums = .loaded(try await provider.getAlbums().execute())
        } catch {
            guard !error.isCancellation else { return }
            albums = .failed(AppError.from(error))
        }
    }

    @MainActor
    func fetchAlbumPhotos(tagId: Int) async {
        albumPhotos = .loading
        do {
            albumPhotos = .loaded(try await provider.getAlbumPhotos().execute(tagId: tagId))
        } catch {
            guard !error.isCancellation else { return }
            albumPhotos = .failed(AppError.from(error))
        }
    }
}
