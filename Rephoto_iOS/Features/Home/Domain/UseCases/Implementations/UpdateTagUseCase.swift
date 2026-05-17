//
//  UpdateTagUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

final class UpdateTagUseCase: UpdateTagUseCaseProtocol {
    private let repository: TagRepositoryProtocol

    init(repository: TagRepositoryProtocol) {
        self.repository = repository
    }

    func execute(photoTagId: Int, tagName: String) async throws -> PhotoTag {
        try await repository.updateTag(photoTagId: photoTagId, tagName: tagName)
    }
}
