//
//  GetAlbumPhotosUseCaseProtocol.swift
//  AlbumDomainInterface
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import PhotoDomainInterface

/// @mockable
public protocol GetAlbumPhotosUseCaseProtocol: Sendable {
    func execute(tagId: Int) async throws -> [Photo]
}
