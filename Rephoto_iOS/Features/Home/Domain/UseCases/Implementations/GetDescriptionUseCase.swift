//
//  GetDescriptionUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

final class GetDescriptionUseCase: GetDescriptionUseCaseProtocol {
    private let repository: DescriptionRepositoryProtocol

    init(repository: DescriptionRepositoryProtocol) {
        self.repository = repository
    }

    func execute(photoId: Int) async throws -> String {
        try await repository.getDescription(photoId: photoId)
    }
}
