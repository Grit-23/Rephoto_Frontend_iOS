//
//  PreviewPhotoRepository.swift
//  PreviewSupport
//
//  Created by Doyeon Kim on 11/4/26.
//

import Foundation
import Synchronization
import PhotoDomainInterface
import RephotoFoundation

/// 사진 목록을 메모리에 들고 있는 Repository. 업로드한 사진은 목록 맨 앞에 추가되어 화면에 바로 보인다.
public final class PreviewPhotoRepository: PhotoRepositoryProtocol, Sendable {
    private let photos: Mutex<[Photo]>

    public init(photos: [Photo] = PreviewPhotoFixtures.photos) {
        self.photos = Mutex(photos)
    }

    public func getAllPhotos() async throws -> [Photo] {
        photos.withLock { $0 }
    }

    public func getPhotos(tagId: Int) async throws -> [Photo] {
        let photoIds = PreviewPhotoFixtures.albumPhotoIds(tagId: tagId)
        let current = photos.withLock { $0 }
        return photoIds.compactMap { photoId in current.first { $0.photoId == photoId } }
    }

    public func deletePhoto(photoId: Int) async throws {
        photos.withLock { $0.removeAll { $0.photoId == photoId } }
    }

    public func uploadPhotos(items: [PhotoUploadItem], onItemUploaded: (@MainActor @Sendable (Int) -> Void)?) async throws {
        for (index, item) in items.enumerated() {
            // 진행 배너가 보이도록 서버 왕복 시간을 흉내 낸다. 취소되면 실제 Repository처럼 여기서 중단된다
            try await Task.sleep(for: .milliseconds(400))
            photos.withLock { photos in
                let nextId = (photos.map(\.photoId).max() ?? 0) + 1
                let photo = Photo(
                    photoId: nextId,
                    imageUrl: item.imageUrl,
                    latitude: item.latitude,
                    longitude: item.longitude,
                    createdAt: DateFormatter.serverISO.date(from: item.createdAt) ?? Date(),
                    fileName: item.fileName,
                    tags: [],
                    isSensitive: false
                )
                photos.insert(photo, at: 0)
            }
            await onItemUploaded?(index + 1)
        }
    }
}
