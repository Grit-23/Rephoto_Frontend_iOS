//
//  AlbumRepositoryProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

protocol AlbumRepositoryProtocol {
    func getAlbums() async throws -> [Album]
    func getAlbumPhotos(tagId: Int) async throws -> [Photo]
}
