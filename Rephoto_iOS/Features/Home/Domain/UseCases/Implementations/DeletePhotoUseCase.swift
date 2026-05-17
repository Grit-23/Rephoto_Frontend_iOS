//
//  DeletePhotoUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

final class DeletePhotoUseCase: DeletePhotoUseCaseProtocol {
    private let repository: PhotoRepositoryProtocol

    init(repository: PhotoRepositoryProtocol) {
        self.repository = repository
    }

    func execute(photoId: Int) async throws {
        try await repository.deletePhoto(photoId: photoId)
    }
}
