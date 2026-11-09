//
//  AlbumRepository.swift
//  AlbumDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import NetworkAdapter
import AlbumDomainInterface

/// Approachable Concurrency에서는 nonisolated async가 호출자 액터에서 돌므로,
/// 디코딩이 메인 액터 위에서 실행되지 않도록 `@concurrent`로 내보낸다.
/// 앨범의 사진 목록은 사진 응답 형식이라 PhotoDomain의 `PhotoRepositoryProtocol.getPhotos(tagId:)`가 맡는다.
public final class AlbumRepository: AlbumRepositoryProtocol, Sendable {
    private let adapter: NetworkAdapter
    private let decoder: JSONDecoder

    public init(adapter: NetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    @concurrent
    public func getAlbums() async throws -> [Album] {
        let data = try await adapter.request(AlbumAPITarget.getAlbumList)
        let dtos = try decoder.decode([AlbumResponseDTO].self, from: data)
        return dtos.map { $0.toDomain() }
    }
}
