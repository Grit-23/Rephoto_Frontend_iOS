//
//  SearchUseCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

final class SearchUseCase: SearchUseCaseProtocol {
    private let repository: SearchRepositoryProtocol
    
    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(query: String) async throws -> [SearchResult] {
        try await repository.search(query: query)
    }
}
