//
//  UploadPhotosUseCaseProtocol.swift
//  PhotoDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

/// @mockable
public protocol UploadPhotosUseCaseProtocol: Sendable {
    /// - Parameter onItemUploaded: 개별 사진 업로드 완료 시마다 누적 완료 개수를 메인 액터에서 전달
    func execute(items: [PhotoUploadItem], onItemUploaded: (@MainActor @Sendable (Int) -> Void)?) async throws
}

extension UploadPhotosUseCaseProtocol {
    public func execute(items: [PhotoUploadItem]) async throws {
        try await execute(items: items, onItemUploaded: nil)
    }
}
