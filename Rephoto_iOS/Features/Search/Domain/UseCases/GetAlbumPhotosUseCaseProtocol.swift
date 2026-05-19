//
//  GetAlbumPhotosUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

protocol GetAlbumPhotosUseCaseProtocol {
    func execute(tagId: Int) async throws -> [Photo]
}
