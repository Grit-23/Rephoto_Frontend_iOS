//
//  PhotoInfoViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

@Observable
final class PhotoInfoViewModel {
    private let provider: HomeUseCaseProviderProtocol

    private(set) var isDeleted: Bool = false
    private(set) var tags: [PhotoTag] = []
    private(set) var description: String = ""
    private(set) var errorMessage: String?

    init(provider: HomeUseCaseProviderProtocol) {
        self.provider = provider
    }

    @MainActor
    func deletePhoto(photoId: Int) async {
        do {
            try await provider.makeDeletePhotoUseCase().execute(photoId: photoId)
            isDeleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func fetchTags(photoId: Int) async {
        do {
            tags = try await provider.makeGetTagsUseCase().execute(photoId: photoId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func addTag(photoId: Int, tagName: String) async {
        do {
            let newTag = try await provider.makeAddTagUseCase().execute(photoId: photoId, tagName: tagName)
            tags.append(newTag)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func updateTag(photoTagId: Int, newTagName: String) async {
        do {
            let updated = try await provider.makeUpdateTagUseCase().execute(photoTagId: photoTagId, tagName: newTagName)
            if let index = tags.firstIndex(where: { $0.photoTagId == photoTagId }) {
                tags[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func getDescription(photoId: Int) async {
        do {
            description = try await provider.makeGetDescriptionUseCase().execute(photoId: photoId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
