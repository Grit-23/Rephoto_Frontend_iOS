//
//  GetAlbumPhotosUseCase.swift
//  AlbumDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import AlbumDomainInterface
import PhotoDomainInterface

public final class GetAlbumPhotosUseCase: GetAlbumPhotosUseCaseProtocol {
    private let repository: any PhotoRepositoryProtocol

    public init(repository: any PhotoRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(tagId: Int) async throws -> [Photo] {
        try await repository.getPhotos(tagId: tagId)
    }
}
