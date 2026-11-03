//
//  AddTagUseCase.swift
//  TagDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import TagDomainInterface

public final class AddTagUseCase: AddTagUseCaseProtocol {
    private let repository: any TagRepositoryProtocol

    public init(repository: any TagRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(photoId: Int, tagName: String) async throws -> PhotoTag {
        try await repository.addTag(photoId: photoId, tagName: tagName)
    }
}
