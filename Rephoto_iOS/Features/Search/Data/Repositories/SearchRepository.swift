//
//  SearchRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import Moya

final class SearchRepository: SearchRepositoryProtocol {
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func search(query: String) async throws -> [SearchResult] {
        let response = try await adapter.request(SearchAPITarget.search(query: query))
        let dto = try decoder.decode(SearchResponseDTO.self, from: response.data)
        return dto.searchResults.map { $0.toDomain() }
    }
}

