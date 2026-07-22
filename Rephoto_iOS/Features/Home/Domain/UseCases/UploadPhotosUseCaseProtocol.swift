//
//  UploadPhotosUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

protocol UploadPhotosUseCaseProtocol {
    /// - Parameter onItemUploaded: 개별 사진 업로드 완료 시마다 누적 완료 개수를 전달
    func execute(items: [PhotoUploadItem], onItemUploaded: ((Int) -> Void)?) async throws
}

extension UploadPhotosUseCaseProtocol {
    func execute(items: [PhotoUploadItem]) async throws {
        try await execute(items: items, onItemUploaded: nil)
    }
}
