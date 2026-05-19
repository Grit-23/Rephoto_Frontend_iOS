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
    
    private(set) var albums: [Album] = []
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

