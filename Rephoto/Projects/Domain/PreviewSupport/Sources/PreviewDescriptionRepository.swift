//
//  PreviewDescriptionRepository.swift
//  PreviewSupport
//
//  Created by Doyeon Kim on 11/4/26.
//

import Foundation
import PhotoDomainInterface

/// 픽스처의 AI 설명을 돌려주는 Repository. 픽스처에 없는 사진(업로드한 사진)은 빈 문자열.
public struct PreviewDescriptionRepository: DescriptionRepositoryProtocol, Sendable {
    public init() {}

    public func getDescription(photoId: Int) async throws -> String {
        PreviewPhotoFixtures.entry(photoId: photoId)?.description ?? ""
    }
}
