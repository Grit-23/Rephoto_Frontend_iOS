//
//  DeleteTagUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/17/26.
//

import Foundation

final class DeleteTagUseCase: DeleteTagUseCaseProtocol {
    private let repository: TagRepositoryProtocol

    init(repository: TagRepositoryProtocol) {
        self.repository = repository
    }

    func execute(photoTagId: Int) async throws {
        try await repository.deleteTag(photoTagId: photoTagId)
    }
}
