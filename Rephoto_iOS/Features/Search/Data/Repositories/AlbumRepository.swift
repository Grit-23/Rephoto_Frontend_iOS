//
//  AlbumRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import Moya

final class AlbumRepository: AlbumRepositoryProtocol {
    private let provider: MoyaProvider<AlbumAPITarget>
    private let decoder: JSONDecoder
    
    init(provider: MoyaProvider<AlbumAPITarget>, decoder: JSONDecoder = JSONDecoder()) {
        self.provider = provider
        self.decoder = decoder
    }
    
    func getAlbums() async throws -> [Album] {
        let response = try await provider.request(.getAlbumList)
        let dtos = try decoder.decode([AlbumResponseDTO].self, from: response.data)
        return dtos.map { $0.toDomain() }
    }

    func getAlbumPhotos(tagId: Int) async throws -> [Photo] {
        let response = try await provider.request(.getAlbumInfo(tagId: tagId))
        let dtos = try decoder.decode([PhotoResponseDTO].self, from: response.data)
        return try dtos.map { try $0.toDomain() }
    }
    
}
