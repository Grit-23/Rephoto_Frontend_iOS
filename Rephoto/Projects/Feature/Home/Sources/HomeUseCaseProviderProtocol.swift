//
//  HomeUseCaseProviderProtocol.swift
//  HomeFeature
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import PhotoDomainInterface
import TagDomainInterface

/// Home 화면이 쓰는 UseCase를 만드는 공장. 구현은 App(서버 Repository)과 Example(PreviewSupport)이 각각 조립한다.
public protocol HomeUseCaseProviderProtocol: Sendable {
    func makeGetPhotosUseCase() -> any GetPhotosUseCaseProtocol
    func makeUploadPhotosUseCase() -> any UploadPhotosUseCaseProtocol
    func makeExtractPhotoMetadataUseCase() -> any ExtractPhotoMetadataUseCaseProtocol
    func makeDeletePhotoUseCase() -> any DeletePhotoUseCaseProtocol
    func makeGetTagsUseCase() -> any GetTagsUseCaseProtocol
    func makeAddTagUseCase() -> any AddTagUseCaseProtocol
    func makeUpdateTagUseCase() -> any UpdateTagUseCaseProtocol
    func makeDeleteTagUseCase() -> any DeleteTagUseCaseProtocol
    func makeGetDescriptionUseCase() -> any GetDescriptionUseCaseProtocol
}
