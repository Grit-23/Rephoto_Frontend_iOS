//
//  SearchRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import Moya

final class SearchRepository: SearchRepositoryProtocol {
    private let provider: MoyaProvider<SearchAPITarget>
    private let decoder: JSONDecoder
    
    init(provider: MoyaProvider<SearchAPITarget>, decoder: JSONDecoder = JSONDecoder()) {
        self.provider = provider
        self.decoder = decoder
    }
    
    func search(query: String) async throws -> [SearchResult] {
        let response = try await provider.request(.search(query: query))
        let dto = try decoder.decode(SearchResponseDTO.self, from: response.data)
        return dto.searchResults.map { $0.toDomain() }
    }
}

