//
//  DeleteTagUseCase.swift
//  TagDomain
//
//  Created by 김도연 on 7/17/26.
//

import Foundation
import TagDomainInterface

public final class DeleteTagUseCase: DeleteTagUseCaseProtocol {
    private let repository: any TagRepositoryProtocol

    public init(repository: any TagRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(photoTagId: Int) async throws {
        try await repository.deleteTag(photoTagId: photoTagId)
    }
}
