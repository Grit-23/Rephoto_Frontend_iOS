//
//  UploadPhotosUseCase.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import PhotoDomainInterface

public final class UploadPhotosUseCase: UploadPhotosUseCaseProtocol {
    private let repository: any PhotoRepositoryProtocol

    public init(repository: any PhotoRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(items: [PhotoUploadItem], onItemUploaded: (@MainActor @Sendable (Int) -> Void)?) async throws {
        guard !items.isEmpty else { return }
        try await repository.uploadPhotos(items: items, onItemUploaded: onItemUploaded)
    }
}
