//
//  TagRepository.swift
//  TagDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import NetworkAdapter
import TagDomainInterface

/// Approachable Concurrency에서는 nonisolated async가 호출자 액터에서 돌므로,
/// 디코딩이 메인 액터 위에서 실행되지 않도록 `@concurrent`로 내보낸다.
public final class TagRepository: TagRepositoryProtocol, Sendable {
    private let adapter: NetworkAdapter
    private let decoder: JSONDecoder

    public init(adapter: NetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    @concurrent
    public func getTags(photoId: Int) async throws -> [PhotoTag] {
        let data = try await adapter.request(TagAPITarget.getTags(photoId: photoId))
        let dtos = try decoder.decode([TagResponseDTO].self, from: data)
        return dtos.map { $0.toDomain() }
    }

    @concurrent
    public func addTag(photoId: Int, tagName: String) async throws -> PhotoTag {
        let request = AddTagRequestDTO(photoId: photoId, tagName: tagName)
        let data = try await adapter.request(TagAPITarget.addTag(request: request))
        let dto = try decoder.decode(TagResponseDTO.self, from: data)
        return dto.toDomain()
    }

    @concurrent
    public func updateTag(photoTagId: Int, tagName: String) async throws -> PhotoTag {
        let request = UpdateTagRequestDTO(tagName: tagName)
        let data = try await adapter.request(TagAPITarget.updateTag(photoTagId: photoTagId, request: request))
        let dto = try decoder.decode(TagResponseDTO.self, from: data)
        return dto.toDomain()
    }

    public func deleteTag(photoTagId: Int) async throws {
        _ = try await adapter.request(TagAPITarget.deleteTag(photoTagId: photoTagId))
    }
}
