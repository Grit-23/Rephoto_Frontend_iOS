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

    func execute(items: [PhotoUploadItem]) async throws {
        guard !items.isEmpty else { return }
        try await repository.uploadPhotos(items: items)
    }
}
