//
//  AlbumViewModel.swift
//  SearchFeature
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import AlbumDomainInterface
import PhotoDomainInterface
import RephotoFoundation

@Observable
final class AlbumViewModel {
    private let provider: any SearchUseCaseProviderProtocol

    /// "앨범이 없음"과 "앨범을 못 불러옴"이 섞이지 않도록 Loadable로 상태를 나눈다
    private(set) var albums: Loadable<[Album]> = .idle
    private(set) var albumPhotos: Loadable<[Photo]> = .idle

    init(provider: any SearchUseCaseProviderProtocol) {
        self.provider = provider
    }

    /// 상세에서 돌아올 때마다 다시 불리므로, 이미 목록이 있으면 `.loading`으로 바꾸지 않고 교체만 한다.
    /// 목록이 있을 때의 갱신 실패는 이전 목록을 유지한다 — 홈이 사진이 있을 때 목록을 지키는 규칙과 같다.
    func fetchAlbums() async {
        if albums.value == nil { albums = .loading }
        do {
            albums = .loaded(try await provider.makeGetAlbumsUseCase().execute())
        } catch {
            guard !error.isCancellation, albums.value == nil else { return }
            albums = .failed(AppError.from(error))
        }
    }

    func fetchAlbumPhotos(tagId: Int) async {
        if albumPhotos.value == nil { albumPhotos = .loading }
        do {
            albumPhotos = .loaded(try await provider.makeGetAlbumPhotosUseCase().execute(tagId: tagId))
        } catch {
            guard !error.isCancellation, albumPhotos.value == nil else { return }
            albumPhotos = .failed(AppError.from(error))
        }
    }
}
