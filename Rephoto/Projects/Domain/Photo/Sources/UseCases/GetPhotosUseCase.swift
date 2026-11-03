//
//  GetPhotosUseCase.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import PhotoDomainInterface

public final class GetPhotosUseCase: GetPhotosUseCaseProtocol {
    private let repository: any PhotoRepositoryProtocol

    public init(repository: any PhotoRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Photo] {
        try await repository.getAllPhotos()
    }
}
