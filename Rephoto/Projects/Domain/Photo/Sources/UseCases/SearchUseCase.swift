//
//  SearchUseCase.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import PhotoDomainInterface

public final class SearchUseCase: SearchUseCaseProtocol {
    private let repository: any SearchRepositoryProtocol

    public init(repository: any SearchRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(query: String) async throws -> [SearchResult] {
        try await repository.search(query: query)
    }
}
