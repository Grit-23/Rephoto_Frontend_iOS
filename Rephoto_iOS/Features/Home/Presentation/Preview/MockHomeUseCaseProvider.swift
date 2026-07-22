//
//  MockHomeUseCaseProvider.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

#if DEBUG
import Foundation

final class MockHomeUseCaseProvider: HomeUseCaseProviderProtocol {
    func makeGetPhotosUseCase() -> GetPhotosUseCaseProtocol { MockGetPhotosUseCase() }
    func makeUploadPhotosUseCase() -> UploadPhotosUseCaseProtocol { MockUploadPhotosUseCase() }
    func makeExtractPhotoMetadataUseCase() -> ExtractPhotoMetadataUseCaseProtocol { MockExtractPhotoMetadataUseCase() }
    func makeDeletePhotoUseCase() -> DeletePhotoUseCaseProtocol { MockDeletePhotoUseCase() }
    func makeGetTagsUseCase() -> GetTagsUseCaseProtocol { MockGetTagsUseCase() }
    func makeAddTagUseCase() -> AddTagUseCaseProtocol { MockAddTagUseCase() }
    func makeUpdateTagUseCase() -> UpdateTagUseCaseProtocol { MockUpdateTagUseCase() }
    func makeDeleteTagUseCase() -> DeleteTagUseCaseProtocol { MockDeleteTagUseCase() }
    func makeGetDescriptionUseCase() -> GetDescriptionUseCaseProtocol { MockGetDescriptionUseCase() }
}

// MARK: - Mock UseCases

private struct MockGetPhotosUseCase: GetPhotosUseCaseProtocol {
    func execute() async throws -> [Photo] {
        (1...12).map { i in
            Photo(
                photoId: i,
                imageUrl: URL(string: "https://picsum.photos/seed/home-\(i)/400")!,
                latitude: 37.5665,
                longitude: 126.9780,
                createdAt: Date(),
                fileName: "photo_\(i).jpg",
                tags: ["서울", "여행"],
                isSensitive: i == 5
            )
        }
    }
}

private struct MockUploadPhotosUseCase: UploadPhotosUseCaseProtocol {
    func execute(items: [PhotoUploadItem], onItemUploaded: ((Int) -> Void)?) async throws {
        for index in items.indices {
            try? await Task.sleep(for: .milliseconds(400))
            onItemUploaded?(index + 1)
        }
    }
}

private struct MockExtractPhotoMetadataUseCase: ExtractPhotoMetadataUseCaseProtocol {
    // nil을 반환하면 업로드 파이프라인이 조기 종료되어 진행 배너를 확인할 수 없으므로,
    // 데모에서도 실제 업로드 흐름을 타도록 유효한 아이템을 반환
    func execute(imageData: Data, identifier: String?) async -> PhotoUploadItem? {
        let fileName = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? imageData.write(to: url)
        return PhotoUploadItem(
            latitude: 37.5665,
            longitude: 126.9780,
            imageUrl: url,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            fileName: fileName
        )
    }
}

private struct MockDeletePhotoUseCase: DeletePhotoUseCaseProtocol {
    func execute(photoId: Int) async throws {}
}

private struct MockGetTagsUseCase: GetTagsUseCaseProtocol {
    func execute(photoId: Int) async throws -> [PhotoTag] {
        [
            PhotoTag(photoTagId: 1, tagId: 1, tagName: "서울", photoId: photoId),
            PhotoTag(photoTagId: 2, tagId: 2, tagName: "여행", photoId: photoId),
        ]
    }
}

private struct MockAddTagUseCase: AddTagUseCaseProtocol {
    func execute(photoId: Int, tagName: String) async throws -> PhotoTag {
        PhotoTag(photoTagId: 99, tagId: 99, tagName: tagName, photoId: photoId)
    }
}

private struct MockDeleteTagUseCase: DeleteTagUseCaseProtocol {
    func execute(photoTagId: Int) async throws {}
}

private struct MockUpdateTagUseCase: UpdateTagUseCaseProtocol {
    func execute(photoTagId: Int, tagName: String) async throws -> PhotoTag {
        PhotoTag(photoTagId: photoTagId, tagId: 1, tagName: tagName, photoId: 1)
    }
}

private struct MockGetDescriptionUseCase: GetDescriptionUseCaseProtocol {
    func execute(photoId: Int) async throws -> String {
        "서울 남산타워에서 찍은 사진입니다."
    }
}
#endif
