//
//  DescriptionRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import Moya

final class DescriptionRepository: DescriptionRepositoryProtocol {
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func getDescription(photoId: Int) async throws -> String {
        let response = try await adapter.request(DescriptionAPITarget.getDescription(photoId: photoId))
        let dto = try decoder.decode(DescriptionResponseDTO.self, from: response.data)
        return dto.description
    }
}
