//
//  SearchUseCaseProvider.swift
//  Rephoto
//
//  Created by Doyeon Kim on 11/10/26.
//

import Foundation
import AlbumDomain
import AlbumDomainInterface
import PhotoDomain
import PhotoDomainInterface
import SearchFeature

/// 앨범 사진 · 색인은 Home과 같은 `PhotoRepository`를 받는다 — 서버 · Preview 어느 쪽이든 Home과 같은 사진을 본다.
final class SearchUseCaseProvider: SearchUseCaseProviderProtocol {
    private let albumRepository: any AlbumRepositoryProtocol
    private let photoRepository: any PhotoRepositoryProtocol
    private let searchRepository: any SearchRepositoryProtocol

    init(
        albumRepository: any AlbumRepositoryProtocol,
        photoRepository: any PhotoRepositoryProtocol,
        searchRepository: any SearchRepositoryProtocol
    ) {
        self.albumRepository = albumRepository
        self.photoRepository = photoRepository
        self.searchRepository = searchRepository
    }

    func makeGetAlbumsUseCase() -> any GetAlbumsUseCaseProtocol {
        GetAlbumsUseCase(repository: albumRepository)
    }

    func makeGetAlbumPhotosUseCase() -> any GetAlbumPhotosUseCaseProtocol {
        GetAlbumPhotosUseCase(repository: photoRepository)
    }

    func makeSearchUseCase() -> any SearchUseCaseProtocol {
        SearchUseCase(repository: searchRepository)
    }

    func makeGetPhotosUseCase() -> any GetPhotosUseCaseProtocol {
        GetPhotosUseCase(repository: photoRepository)
    }
}
