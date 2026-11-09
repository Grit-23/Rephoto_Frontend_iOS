//
//  HomeUseCaseProvider.swift
//  Rephoto
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import HomeFeature
import PhotoDomain
import PhotoDomainInterface
import TagDomain
import TagDomainInterface

final class HomeUseCaseProvider: HomeUseCaseProviderProtocol {
    private let photoRepository: any PhotoRepositoryProtocol
    private let tagRepository: any TagRepositoryProtocol
    private let descriptionRepository: any DescriptionRepositoryProtocol
    private let metadataExtractor: any PhotoMetadataExtractorProtocol

    init(
        photoRepository: any PhotoRepositoryProtocol,
        tagRepository: any TagRepositoryProtocol,
        descriptionRepository: any DescriptionRepositoryProtocol,
        metadataExtractor: any PhotoMetadataExtractorProtocol
    ) {
        self.photoRepository = photoRepository
        self.tagRepository = tagRepository
        self.descriptionRepository = descriptionRepository
        self.metadataExtractor = metadataExtractor
    }

    func makeGetPhotosUseCase() -> any GetPhotosUseCaseProtocol {
        GetPhotosUseCase(repository: photoRepository)
    }

    func makeUploadPhotosUseCase() -> any UploadPhotosUseCaseProtocol {
        UploadPhotosUseCase(repository: photoRepository)
    }

    func makeExtractPhotoMetadataUseCase() -> any ExtractPhotoMetadataUseCaseProtocol {
        ExtractPhotoMetadataUseCase(extractor: metadataExtractor)
    }

    func makeDeletePhotoUseCase() -> any DeletePhotoUseCaseProtocol {
        DeletePhotoUseCase(repository: photoRepository)
    }

    func makeGetTagsUseCase() -> any GetTagsUseCaseProtocol {
        GetTagsUseCase(repository: tagRepository)
    }

    func makeAddTagUseCase() -> any AddTagUseCaseProtocol {
        AddTagUseCase(repository: tagRepository)
    }

    func makeUpdateTagUseCase() -> any UpdateTagUseCaseProtocol {
        UpdateTagUseCase(repository: tagRepository)
    }

    func makeDeleteTagUseCase() -> any DeleteTagUseCaseProtocol {
        DeleteTagUseCase(repository: tagRepository)
    }

    func makeGetDescriptionUseCase() -> any GetDescriptionUseCaseProtocol {
        GetDescriptionUseCase(repository: descriptionRepository)
    }
}
