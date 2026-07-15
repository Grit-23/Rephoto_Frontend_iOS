//
//  AlbumRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

final class AlbumRepository: AlbumRepositoryProtocol {
    private let adapter: NetworkAdapter
    private let decoder: JSONDecoder

    init(adapter: NetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func getAlbums() async throws -> [Album] {
        let response = try await adapter.request(AlbumAPITarget.getAlbumList)
        let dtos = try decoder.decode([AlbumResponseDTO].self, from: response.data)
        return dtos.map { $0.toDomain() }
    }

    func getAlbumPhotos(tagId: Int) async throws -> [Photo] {
        let response = try await adapter.request(AlbumAPITarget.getAlbumInfo(tagId: tagId))
        let dtos = try decoder.decode([PhotoResponseDTO].self, from: response.data)
        return try dtos.map { try $0.toDomain() }
    }
}
