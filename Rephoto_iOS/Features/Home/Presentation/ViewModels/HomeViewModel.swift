//
//  HomeViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI
import PhotosUI

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
    func handlePickedPhotos(_ pickerItems: [PhotosPickerItem]) async {
        isLoading = true
        errorMessage = nil

        let items = await withTaskGroup(of: PhotoUploadItem?.self, returning: [PhotoUploadItem].self) { group in
            for pickerItem in pickerItems {
                group.addTask {
                    await PhotoMetadataExtractor.extract(from: pickerItem)
                }
            }
            var results: [PhotoUploadItem] = []
            for await item in group {
                if let item { results.append(item) }
            }
            return results
        }

        guard !items.isEmpty else {
            isLoading = false
            return
        }

        do {
            try await provider.makeUploadPhotosUseCase().execute(items: items)
            await fetchPhotos()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
