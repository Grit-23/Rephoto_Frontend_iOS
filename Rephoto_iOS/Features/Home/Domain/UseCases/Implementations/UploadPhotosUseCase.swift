//
//  UploadPhotosUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

final class UploadPhotosUseCase: UploadPhotosUseCaseProtocol {
    private let repository: PhotoRepositoryProtocol

    init(repository: PhotoRepositoryProtocol) {
        self.repository = repository
    }

    func execute(items: [PhotoMetadataDTO]) async throws {
        guard !items.isEmpty else { return }

        var uploaded: [PhotoMetadataDTO] = []

        for item in items {
            guard let fileData = try? Data(contentsOf: URL(string: item.imageUrl)!) else { continue }
            let urlString = try await repository.uploadToS3(file: fileData)
            let meta = PhotoMetadataDTO(
                latitude: item.latitude,
                longitude: item.longitude,
                imageUrl: urlString,
                createdAt: item.createdAt,
                fileName: item.fileName
            )
            uploaded.append(meta)
        }

        guard !uploaded.isEmpty else { return }
        try await repository.savePhotosBatch(photos: uploaded)
    }
}
