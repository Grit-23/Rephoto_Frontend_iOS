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
    /// 태그·설명 변경 실패는 이전까지 어떤 화면에도 표시되지 않고 삼켜졌다.
    /// 사용자가 시작한 작업이 실패한 것이므로 전역 Alert으로 알린다.
    private let errorHandler: ErrorHandler

    private(set) var isDeleted: Bool = false
    private(set) var tags: [PhotoTag] = []
    private(set) var description: String = ""

    init(provider: HomeUseCaseProviderProtocol, errorHandler: ErrorHandler) {
        self.provider = provider
        self.errorHandler = errorHandler
    }

    @MainActor
    func deletePhoto(photoId: Int) async {
        do {
            try await provider.makeDeletePhotoUseCase().execute(photoId: photoId)
            isDeleted = true
        } catch {
            report(error, action: "deletePhoto") { [weak self] in
                await self?.deletePhoto(photoId: photoId)
            }
        }
    }

    @MainActor
    func fetchTags(photoId: Int) async {
        do {
            tags = try await provider.makeGetTagsUseCase().execute(photoId: photoId)
        } catch {
            report(error, action: "fetchTags") { [weak self] in
                await self?.fetchTags(photoId: photoId)
            }
        }
    }

    @MainActor
    func addTag(photoId: Int, tagName: String) async {
        do {
            let newTag = try await provider.makeAddTagUseCase().execute(photoId: photoId, tagName: tagName)
            tags.append(newTag)
        } catch {
            report(error, action: "addTag") { [weak self] in
                await self?.addTag(photoId: photoId, tagName: tagName)
            }
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
            report(error, action: "updateTag") { [weak self] in
                await self?.updateTag(photoTagId: photoTagId, newTagName: newTagName)
            }
        }
    }

    @MainActor
    func deleteTag(photoTagId: Int) async {
        do {
            try await provider.makeDeleteTagUseCase().execute(photoTagId: photoTagId)
            tags.removeAll { $0.photoTagId == photoTagId }
        } catch {
            report(error, action: "deleteTag") { [weak self] in
                await self?.deleteTag(photoTagId: photoTagId)
            }
        }
    }

    @MainActor
    func getDescription(photoId: Int) async {
        do {
            description = try await provider.makeGetDescriptionUseCase().execute(photoId: photoId)
        } catch {
            report(error, action: "getDescription") { [weak self] in
                await self?.getDescription(photoId: photoId)
            }
        }
    }

    // MARK: - Private

    @MainActor
    private func report(
        _ error: Error,
        action: String,
        retry: @escaping () async -> Void
    ) {
        errorHandler.handle(error, context: ErrorContext(
            feature: "PhotoInfo",
            action: action,
            retryAction: retry
        ))
    }
}
