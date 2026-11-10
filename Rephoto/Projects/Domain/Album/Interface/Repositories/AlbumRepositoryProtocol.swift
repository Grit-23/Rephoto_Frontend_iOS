//
//  AlbumRepositoryProtocol.swift
//  AlbumDomainInterface
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

/// @mockable
public protocol AlbumRepositoryProtocol: Sendable {
    func getAlbums() async throws -> [Album]
}
