//
//  ExampleHomeProvider.swift
//  HomeFeatureExample
//
//  Created by Doyeon Kim on 11/6/26.
//

import Foundation
import HomeFeature
import PhotoDomain
import PhotoDomainInterface
import PreviewSupport
import TagDomain
import TagDomainInterface

/// PreviewSupport Repository + 실제 UseCase · Extractor. App의 `HomeUseCaseProvider`와 같은 모양으로 조립한다.
final class ExampleHomeProvider: HomeUseCaseProviderProtocol {
    private let photoRepository = PreviewPhotoRepository()
    private let tagRepository = PreviewTagRepository()
    private let descriptionRepository = PreviewDescriptionRepository()
    private let metadataExtractor = PhotoMetadataExtractor()

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
