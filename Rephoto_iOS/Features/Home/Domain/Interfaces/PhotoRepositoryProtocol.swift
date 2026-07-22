//
//  PhotoRepositoryProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

protocol PhotoRepositoryProtocol {
    func getAllPhotos() async throws -> [Photo]
    func deletePhoto(photoId: Int) async throws
    /// - Parameter onItemUploaded: 개별 사진 업로드 완료 시마다 누적 완료 개수를 전달
    func uploadPhotos(items: [PhotoUploadItem], onItemUploaded: ((Int) -> Void)?) async throws
}

extension PhotoRepositoryProtocol {
    func uploadPhotos(items: [PhotoUploadItem]) async throws {
        try await uploadPhotos(items: items, onItemUploaded: nil)
    }
}
