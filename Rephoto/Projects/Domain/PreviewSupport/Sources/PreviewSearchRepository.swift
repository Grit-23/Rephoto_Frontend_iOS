//
//  PreviewSearchRepository.swift
//  PreviewSupport
//
//  Created by Doyeon Kim on 11/9/26.
//

import Foundation
import PhotoDomainInterface

/// 픽스처의 태그와 AI 설명에서 검색어를 찾는 Repository. 민감 사진은 결과에서 뺀다.
public struct PreviewSearchRepository: SearchRepositoryProtocol, Sendable {
    public init() {}

    public func search(query: String) async throws -> [SearchResult] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }

        return PreviewPhotoFixtures.entries.enumerated().compactMap { index, entry in
            guard !entry.isSensitive else { return nil }
            let matched = entry.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                || entry.description.localizedCaseInsensitiveContains(query)
            guard matched else { return nil }
            return SearchResult(
                imageUrl: PreviewPhotoFixtures.imageUrl(fileName: entry.fileName),
                photoId: index + 1
            )
        }
    }
}
