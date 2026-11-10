//
//  PreviewAlbumRepository.swift
//  PreviewSupport
//
//  Created by Doyeon Kim on 11/9/26.
//

import Foundation
import AlbumDomainInterface
import PhotoDomainInterface

/// 픽스처 앨범 구성을 현재 사진 상태로 집계하는 Repository.
///
/// 사진은 주입받은 `PhotoRepositoryProtocol`에서 읽는다 — Example · App이 Home과 공유하는 `PreviewPhotoRepository`를
/// 넘기므로 삭제된 사진은 장수 · 커버에서 빠지고, 사진이 하나도 남지 않은 앨범은 서버처럼 목록에서 사라진다.
public struct PreviewAlbumRepository: AlbumRepositoryProtocol, Sendable {
    private let photoRepository: any PhotoRepositoryProtocol

    public init(photoRepository: any PhotoRepositoryProtocol) {
        self.photoRepository = photoRepository
    }

    public func getAlbums() async throws -> [Album] {
        var albums: [Album] = []
        for (index, group) in PreviewPhotoFixtures.albumGroups.enumerated() {
            let tagId = index + 1
            let photos = try await photoRepository.getPhotos(tagId: tagId)
            guard let cover = photos.first else { continue }
            albums.append(
                Album(tagId: tagId, tagName: group.tagName, coverImageUrl: cover.imageUrl, photoCount: photos.count)
            )
        }
        return albums
    }
}
