//
//  TagRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

final class TagRepository: TagRepositoryProtocol {
    private let adapter: NetworkAdapter
    private let decoder: JSONDecoder

    init(adapter: NetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func getTags(photoId: Int) async throws -> [PhotoTag] {
        let response = try await adapter.request(TagAPITarget.getTags(photoId: photoId))
        let dtos = try decoder.decode([TagResponseDTO].self, from: response.data)
        return dtos.map { $0.toDomain() }
    }

    func addTag(photoId: Int, tagName: String) async throws -> PhotoTag {
        let request = AddTagRequestDTO(photoId: photoId, tagName: tagName)
        let response = try await adapter.request(TagAPITarget.addTag(request: request))
        let dto = try decoder.decode(TagResponseDTO.self, from: response.data)
        return dto.toDomain()
    }

    func updateTag(photoTagId: Int, tagName: String) async throws -> PhotoTag {
        let request = UpdateTagRequestDTO(tagName: tagName)
        let response = try await adapter.request(TagAPITarget.updateTag(photoTagId: photoTagId, request: request))
        let dto = try decoder.decode(TagResponseDTO.self, from: response.data)
        return dto.toDomain()
    }

    func deleteTag(photoTagId: Int) async throws {
        _ = try await adapter.request(TagAPITarget.deleteTag(photoTagId: photoTagId))
    }
}
