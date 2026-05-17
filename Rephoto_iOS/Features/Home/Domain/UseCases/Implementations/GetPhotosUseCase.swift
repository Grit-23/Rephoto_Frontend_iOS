//
//  GetPhotosUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

final class GetPhotosUseCase: GetPhotosUseCaseProtocol {
    private let repository: PhotoRepositoryProtocol

    init(repository: PhotoRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [Photo] {
        try await repository.getAllPhotos()
    }
}
