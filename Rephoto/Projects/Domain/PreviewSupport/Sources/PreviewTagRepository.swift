//
//  PreviewTagRepository.swift
//  PreviewSupport
//
//  Created by Doyeon Kim on 11/4/26.
//

import Foundation
import Synchronization
import TagDomainInterface

/// 사진별 태그를 메모리에 들고 있는 Repository. 추가 · 수정 · 삭제가 다음 조회에 반영된다.
public final class PreviewTagRepository: TagRepositoryProtocol, Sendable {
    private struct State {
        var tagsByPhoto: [Int: [PhotoTag]]
        /// 픽스처 태그 id(`photoId * 10 + index`)와 겹치지 않는 범위에서 시작한다
        var nextTagId = 9000
    }

    private let state: Mutex<State>

    public init(tagsByPhoto: [Int: [PhotoTag]] = PreviewTagRepository.fixtureTags()) {
        self.state = Mutex(State(tagsByPhoto: tagsByPhoto))
    }

    public static func fixtureTags() -> [Int: [PhotoTag]] {
        Dictionary(uniqueKeysWithValues: PreviewPhotoFixtures.entries.indices.map { index in
            let photoId = index + 1
            return (photoId, PreviewPhotoFixtures.tags(photoId: photoId))
        })
    }

    public func getTags(photoId: Int) async throws -> [PhotoTag] {
        state.withLock { $0.tagsByPhoto[photoId] ?? [] }
    }

    public func addTag(photoId: Int, tagName: String) async throws -> PhotoTag {
        state.withLock { state in
            let id = state.nextTagId
            state.nextTagId += 1
            let tag = PhotoTag(photoTagId: id, tagId: id, tagName: tagName, photoId: photoId)
            state.tagsByPhoto[photoId, default: []].append(tag)
            return tag
        }
    }

    public func updateTag(photoTagId: Int, tagName: String) async throws -> PhotoTag {
        state.withLock { state in
            for (photoId, tags) in state.tagsByPhoto {
                guard let index = tags.firstIndex(where: { $0.photoTagId == photoTagId }) else { continue }
                let updated = PhotoTag(photoTagId: photoTagId, tagId: tags[index].tagId, tagName: tagName, photoId: photoId)
                state.tagsByPhoto[photoId]?[index] = updated
                return updated
            }
            return PhotoTag(photoTagId: photoTagId, tagId: photoTagId, tagName: tagName, photoId: 0)
        }
    }

    public func deleteTag(photoTagId: Int) async throws {
        state.withLock { state in
            for photoId in state.tagsByPhoto.keys {
                state.tagsByPhoto[photoId]?.removeAll { $0.photoTagId == photoTagId }
            }
        }
    }
}
