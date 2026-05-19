//
//  SearchUseCaseProvider.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

protocol SearchUseCaseProviderProtocol {
    func getAlbums() -> GetAlbumsUseCaseProtocol
    func getAlbumPhotos() -> GetAlbumPhotosUseCaseProtocol
    func searchPhotos() -> SearchUseCaseProtocol
}

final class SearchUseCaseProvider: SearchUseCaseProviderProtocol {
    private let albumRepository: AlbumRepositoryProtocol
    private let searchRepository: SearchRepositoryProtocol

    init(
        albumRepository: AlbumRepositoryProtocol,
        searchRepository: SearchRepositoryProtocol
    ) {
        self.albumRepository = albumRepository
        self.searchRepository = searchRepository
    }
    
    func getAlbums() -> GetAlbumsUseCaseProtocol {
        GetAlbumsUseCase(repository: albumRepository)
    }
    
    func getAlbumPhotos() -> GetAlbumPhotosUseCaseProtocol {
        GetAlbumPhotosUseCase(repository: albumRepository)
    }
    
    func searchPhotos() -> SearchUseCaseProtocol {
        SearchUseCase(repository: searchRepository)
    }
}
