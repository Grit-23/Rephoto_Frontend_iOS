//
//  PreviewAlbumRepository.swift
//  PreviewSupport
//
//  Created by Doyeon Kim on 11/9/26.
//

import Foundation
import AlbumDomainInterface

/// 픽스처 앨범 구성을 돌려주는 Repository. 앨범의 사진 목록은 `PreviewPhotoRepository.getPhotos(tagId:)`가 같은 구성으로 응답한다.
public struct PreviewAlbumRepository: AlbumRepositoryProtocol, Sendable {
    public init() {}

    public func getAlbums() async throws -> [Album] {
        PreviewPhotoFixtures.albumGroups.enumerated().map { index, group in
            Album(
                tagId: index + 1,
                tagName: group.tagName,
                coverImageUrl: group.fileNames.first.map(PreviewPhotoFixtures.imageUrl(fileName:)),
                photoCount: group.fileNames.count
            )
        }
    }
}
