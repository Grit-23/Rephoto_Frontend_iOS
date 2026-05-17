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
    func uploadToS3(file: Data) async throws -> String
    func savePhotosBatch(photos: [PhotoMetadataDTO]) async throws
}
