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
    private struct State {
        var photos: [Photo]
        var nextPhotoId: Int
    }

    private let state: Mutex<State>

    public init(photos: [Photo] = PreviewPhotoFixtures.photos) {
        let maxExistingId = max(photos.map(\.photoId).max() ?? 0, PreviewPhotoFixtures.entries.count)
        self.state = Mutex(State(photos: photos, nextPhotoId: maxExistingId + 1))
    }

    public func getAllPhotos() async throws -> [Photo] {
        state.withLock { $0.photos }
    }

    public func getPhotos(tagId: Int) async throws -> [Photo] {
        let photoIds = PreviewPhotoFixtures.albumPhotoIds(tagId: tagId)
        let current = state.withLock { $0.photos }
        return photoIds.compactMap { photoId in current.first { $0.photoId == photoId } }
    }

    public func deletePhoto(photoId: Int) async throws {
        state.withLock { $0.photos.removeAll { $0.photoId == photoId } }
    }

    public func uploadPhotos(items: [PhotoUploadItem], onItemUploaded: (@MainActor @Sendable (Int) -> Void)?) async throws {
        for (index, item) in items.enumerated() {
            // 진행 배너가 보이도록 서버 왕복 시간을 흉내 낸다. 취소되면 실제 Repository처럼 여기서 중단된다
            try await Task.sleep(for: .milliseconds(400))
            state.withLock { state in
                let photo = Photo(
                    photoId: state.nextPhotoId,
                    imageUrl: item.imageUrl,
                    latitude: item.latitude,
                    longitude: item.longitude,
                    createdAt: DateFormatter.serverISO.date(from: item.createdAt) ?? Date(),
                    fileName: item.fileName,
                    tags: [],
                    isSensitive: false
                )
                state.nextPhotoId += 1
                state.photos.insert(photo, at: 0)
            }
            await onItemUploaded?(index + 1)
        }
    }
}
