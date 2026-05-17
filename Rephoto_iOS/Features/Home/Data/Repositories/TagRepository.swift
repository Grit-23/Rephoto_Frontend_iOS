//
//  TagRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import Moya

final class TagRepository: TagRepositoryProtocol {
    private let provider: MoyaProvider<TagAPITarget>
    private let decoder: JSONDecoder

    init(provider: MoyaProvider<TagAPITarget>, decoder: JSONDecoder = JSONDecoder()) {
        self.provider = provider
        self.decoder = decoder
    }

    func getTags(photoId: Int) async throws -> [PhotoTag] {
        let response = try await provider.request(.getTags(photoId: photoId))
        let dtos = try decoder.decode([TagResponseDTO].self, from: response.data)
        return dtos.map { $0.toDomain() }
    }

    func addTag(photoId: Int, tagName: String) async throws -> PhotoTag {
        let request = AddTagRequestDTO(photoId: photoId, tagName: tagName)
        let response = try await provider.request(.addTag(request: request))
        let dto = try decoder.decode(TagResponseDTO.self, from: response.data)
        return dto.toDomain()
    }

    func updateTag(photoTagId: Int, tagName: String) async throws -> PhotoTag {
        let request = UpdateTagRequestDTO(tagName: tagName)
        let response = try await provider.request(.updateTag(photoTagId: photoTagId, request: request))
        let dto = try decoder.decode(TagResponseDTO.self, from: response.data)
        return dto.toDomain()
    }

    func deleteTag(photoTagId: Int) async throws {
        _ = try await provider.request(.deleteTag(photoTagId: photoTagId))
    }
}
