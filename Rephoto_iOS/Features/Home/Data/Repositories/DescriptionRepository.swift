//
//  DescriptionRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import Moya

final class DescriptionRepository: DescriptionRepositoryProtocol {
    private let provider: MoyaProvider<DescriptionAPITarget>
    private let decoder: JSONDecoder

    init(provider: MoyaProvider<DescriptionAPITarget>, decoder: JSONDecoder = JSONDecoder()) {
        self.provider = provider
        self.decoder = decoder
    }

    func getDescription(photoId: Int) async throws -> String {
        let response = try await provider.request(.getDescription(photoId: photoId))
        let dto = try decoder.decode(DescriptionResponseDTO.self, from: response.data)
        return dto.description
    }
}
