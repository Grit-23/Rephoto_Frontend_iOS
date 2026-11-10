//
//  SearchRepository.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import NetworkAdapter
import PhotoDomainInterface

/// Approachable Concurrency에서는 nonisolated async가 호출자 액터에서 돌므로,
/// 디코딩이 메인 액터 위에서 실행되지 않도록 `@concurrent`로 내보낸다.
public final class SearchRepository: SearchRepositoryProtocol, Sendable {
    private let adapter: NetworkAdapter
    private let decoder: JSONDecoder

    public init(adapter: NetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    @concurrent
    public func search(query: String) async throws -> [SearchResult] {
        let data = try await adapter.request(SearchAPITarget.search(query: query))
        let dto = try decoder.decode(SearchResponseDTO.self, from: data)
        return dto.searchResults.map { $0.toDomain() }
    }
}
