//
//  DeletePhotoUseCase.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import PhotoDomainInterface

public final class DeletePhotoUseCase: DeletePhotoUseCaseProtocol {
    private let repository: any PhotoRepositoryProtocol

    public init(repository: any PhotoRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(photoId: Int) async throws {
        try await repository.deletePhoto(photoId: photoId)
    }
}
