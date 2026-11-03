//
//  DescriptionRepository.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import NetworkAdapter
import PhotoDomainInterface

public final class DescriptionRepository: DescriptionRepositoryProtocol, Sendable {
    private let adapter: NetworkAdapter
    private let decoder: JSONDecoder

    public init(adapter: NetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    @concurrent
    public func getDescription(photoId: Int) async throws -> String {
        let data = try await adapter.request(DescriptionAPITarget.getDescription(photoId: photoId))
        let dto = try decoder.decode(DescriptionResponseDTO.self, from: data)
        return dto.description
    }
}
