//
//  HomeUseCaseProvider.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

protocol HomeUseCaseProviderProtocol {
    func makeGetPhotosUseCase() -> GetPhotosUseCaseProtocol
    func makeUploadPhotosUseCase() -> UploadPhotosUseCaseProtocol
    func makeDeletePhotoUseCase() -> DeletePhotoUseCaseProtocol
    func makeGetTagsUseCase() -> GetTagsUseCaseProtocol
    func makeAddTagUseCase() -> AddTagUseCaseProtocol
    func makeUpdateTagUseCase() -> UpdateTagUseCaseProtocol
    func makeGetDescriptionUseCase() -> GetDescriptionUseCaseProtocol
}

final class HomeUseCaseProvider: HomeUseCaseProviderProtocol {
    private let photoRepository: PhotoRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol
    private let descriptionRepository: DescriptionRepositoryProtocol

    init(
        photoRepository: PhotoRepositoryProtocol,
        tagRepository: TagRepositoryProtocol,
        descriptionRepository: DescriptionRepositoryProtocol
    ) {
        self.photoRepository = photoRepository
        self.tagRepository = tagRepository
        self.descriptionRepository = descriptionRepository
    }

    func makeGetPhotosUseCase() -> GetPhotosUseCaseProtocol {
        GetPhotosUseCase(repository: photoRepository)
    }

    func makeUploadPhotosUseCase() -> UploadPhotosUseCaseProtocol {
        UploadPhotosUseCase(repository: photoRepository)
    }

    func makeDeletePhotoUseCase() -> DeletePhotoUseCaseProtocol {
        DeletePhotoUseCase(repository: photoRepository)
    }

    func makeGetTagsUseCase() -> GetTagsUseCaseProtocol {
        GetTagsUseCase(repository: tagRepository)
    }

    func makeAddTagUseCase() -> AddTagUseCaseProtocol {
        AddTagUseCase(repository: tagRepository)
    }

    func makeUpdateTagUseCase() -> UpdateTagUseCaseProtocol {
        UpdateTagUseCase(repository: tagRepository)
    }

    func makeGetDescriptionUseCase() -> GetDescriptionUseCaseProtocol {
        GetDescriptionUseCase(repository: descriptionRepository)
    }
}
