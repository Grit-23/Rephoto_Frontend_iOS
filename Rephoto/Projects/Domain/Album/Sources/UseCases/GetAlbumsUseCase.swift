//
//  GetAlbumsUseCase.swift
//  AlbumDomain
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import AlbumDomainInterface

public final class GetAlbumsUseCase: GetAlbumsUseCaseProtocol {
    private let repository: any AlbumRepositoryProtocol

    public init(repository: any AlbumRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Album] {
        try await repository.getAlbums()
    }
}
