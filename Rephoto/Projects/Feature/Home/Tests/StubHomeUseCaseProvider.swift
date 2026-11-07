//
//  StubHomeUseCaseProvider.swift
//  HomeFeatureTests
//
//  Created by Doyeon Kim on 11/6/26.
//

import Foundation
import PhotoDomainInterface
import PhotoDomainTesting
import TagDomainInterface
import TagDomainTesting
@testable import HomeFeature

/// mockolo Mock 9개를 들고 있는 Provider. 테스트는 Mock의 Handler를 바꿔 UseCase 응답을 정한다.
final class StubHomeUseCaseProvider: HomeUseCaseProviderProtocol {
    let getPhotos = GetPhotosUseCaseProtocolMock()
    let uploadPhotos = UploadPhotosUseCaseProtocolMock()
    let extractMetadata = ExtractPhotoMetadataUseCaseProtocolMock()
    let deletePhoto = DeletePhotoUseCaseProtocolMock()
    let getTags = GetTagsUseCaseProtocolMock()
    let addTag = AddTagUseCaseProtocolMock()
    let updateTag = UpdateTagUseCaseProtocolMock()
    let deleteTag = DeleteTagUseCaseProtocolMock()
    let getDescription = GetDescriptionUseCaseProtocolMock()

    func makeGetPhotosUseCase() -> any GetPhotosUseCaseProtocol { getPhotos }
    func makeUploadPhotosUseCase() -> any UploadPhotosUseCaseProtocol { uploadPhotos }
    func makeExtractPhotoMetadataUseCase() -> any ExtractPhotoMetadataUseCaseProtocol { extractMetadata }
    func makeDeletePhotoUseCase() -> any DeletePhotoUseCaseProtocol { deletePhoto }
    func makeGetTagsUseCase() -> any GetTagsUseCaseProtocol { getTags }
    func makeAddTagUseCase() -> any AddTagUseCaseProtocol { addTag }
    func makeUpdateTagUseCase() -> any UpdateTagUseCaseProtocol { updateTag }
    func makeDeleteTagUseCase() -> any DeleteTagUseCaseProtocol { deleteTag }
    func makeGetDescriptionUseCase() -> any GetDescriptionUseCaseProtocol { getDescription }
}

// Mock의 @Sendable Handler 안에서 호출되므로 테스트 모듈 기본 격리(MainActor)를 벗어난다
nonisolated extension Photo {
    static func stub(photoId: Int, isSensitive: Bool = false) -> Photo {
        Photo(
            photoId: photoId,
            imageUrl: URL(string: "https://cdn.test/\(photoId).jpg")!,
            latitude: 37.5,
            longitude: 126.9,
            createdAt: Date(timeIntervalSince1970: 0),
            fileName: "\(photoId).jpg",
            tags: [],
            isSensitive: isSensitive
        )
    }
}

nonisolated extension PhotoTag {
    static func stub(photoTagId: Int, name: String, photoId: Int = 1) -> PhotoTag {
        PhotoTag(photoTagId: photoTagId, tagId: photoTagId, tagName: name, photoId: photoId)
    }
}
