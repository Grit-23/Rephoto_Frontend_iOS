//
//  HomeViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

@Observable
final class HomeViewModel {
    let provider: HomeUseCaseProviderProtocol

    private(set) var photos: [Photo] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    var visiblePhotos: [Photo] {
        photos.filter { !$0.isSensitive }
    }

    var warningsCount: Int {
        photos.filter { $0.isSensitive }.count
    }

    init(provider: HomeUseCaseProviderProtocol) {
        self.provider = provider
    }

    @MainActor
    func fetchPhotos() async {
        isLoading = true
        errorMessage = nil
        do {
            photos = try await provider.makeGetPhotosUseCase().execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func uploadPhotos(items: [PhotoUploadItem]) async {
        isLoading = true
        errorMessage = nil
        do {
            try await provider.makeUploadPhotosUseCase().execute(items: items)
            await fetchPhotos()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
