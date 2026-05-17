//
//  GetTagsUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

final class GetTagsUseCase: GetTagsUseCaseProtocol {
    private let repository: TagRepositoryProtocol

    init(repository: TagRepositoryProtocol) {
        self.repository = repository
    }

    func execute(photoId: Int) async throws -> [PhotoTag] {
        try await repository.getTags(photoId: photoId)
    }
}
