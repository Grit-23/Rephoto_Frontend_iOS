//
//  AddTagUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

final class AddTagUseCase: AddTagUseCaseProtocol {
    private let repository: TagRepositoryProtocol

    init(repository: TagRepositoryProtocol) {
        self.repository = repository
    }

    func execute(photoId: Int, tagName: String) async throws -> PhotoTag {
        try await repository.addTag(photoId: photoId, tagName: tagName)
    }
}
