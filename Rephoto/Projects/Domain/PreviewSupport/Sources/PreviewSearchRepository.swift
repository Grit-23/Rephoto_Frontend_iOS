//
//  PreviewSearchRepository.swift
//  PreviewSupport
//
//  Created by Doyeon Kim on 11/9/26.
//

import Foundation
import PhotoDomainInterface

/// 현재 사진 상태에서 태그와 AI 설명으로 검색어를 찾는 Repository. 민감 사진은 결과에서 뺀다.
///
/// 사진은 주입받은 `PhotoRepositoryProtocol`에서 읽으므로 삭제된 사진은 결과에서 빠진다.
/// 업로드한 사진은 픽스처 설명이 없어 태그로만 찾는다.
public struct PreviewSearchRepository: SearchRepositoryProtocol, Sendable {
    private let photoRepository: any PhotoRepositoryProtocol

    public init(photoRepository: any PhotoRepositoryProtocol) {
        self.photoRepository = photoRepository
    }

    public func search(query: String) async throws -> [SearchResult] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }

        let photos = try await photoRepository.getAllPhotos()
        return photos.compactMap { photo in
            guard !photo.isSensitive else { return nil }
            let description = PreviewPhotoFixtures.entry(photoId: photo.photoId)?.description ?? ""
            let matched = photo.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                || description.localizedCaseInsensitiveContains(query)
            guard matched else { return nil }
            return SearchResult(imageUrl: photo.imageUrl, photoId: photo.photoId)
        }
    }
}
