//
//  ExampleSearchProvider.swift
//  SearchFeatureExample
//
//  Created by Doyeon Kim on 11/10/26.
//

import Foundation
import AlbumDomain
import AlbumDomainInterface
import PhotoDomain
import PhotoDomainInterface
import PreviewSupport
import SearchFeature

/// PreviewSupport Repository + 실제 UseCase. App의 `SearchUseCaseProvider`와 같은 모양으로 조립한다.
/// 앨범 · 검색 · 색인이 모두 하나의 `PreviewPhotoRepository`를 보므로 상세에서 삭제한 사진이 목록 · 결과 · 장수에 바로 반영된다.
/// App에서 Home과 Photo Repository 싱글턴을 공유하는 구조와 같다.
final class ExampleSearchProvider: SearchUseCaseProviderProtocol {
    private let photoRepository: PreviewPhotoRepository
    private let albumRepository: PreviewAlbumRepository
    private let searchRepository: PreviewSearchRepository

    init() {
        let photoRepository = PreviewPhotoRepository()
        self.photoRepository = photoRepository
        self.albumRepository = PreviewAlbumRepository(photoRepository: photoRepository)
        self.searchRepository = PreviewSearchRepository(photoRepository: photoRepository)
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
