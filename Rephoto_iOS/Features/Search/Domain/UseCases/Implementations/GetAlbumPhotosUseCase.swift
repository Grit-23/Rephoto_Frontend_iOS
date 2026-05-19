//
//  GetAlbumPhotosUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

final class GetAlbumPhotosUseCase: GetAlbumPhotosUseCaseProtocol {
    private let repository: AlbumRepositoryProtocol
    
    init(repository: AlbumRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(tagId: Int) async throws -> [Photo] {
        try await repository.getAlbumPhotos(tagId: tagId)
    }
}
