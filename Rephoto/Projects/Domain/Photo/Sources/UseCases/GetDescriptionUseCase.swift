//
//  GetDescriptionUseCase.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import PhotoDomainInterface

public final class GetDescriptionUseCase: GetDescriptionUseCaseProtocol {
    private let repository: any DescriptionRepositoryProtocol

    public init(repository: any DescriptionRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(photoId: Int) async throws -> String {
        try await repository.getDescription(photoId: photoId)
    }
}
