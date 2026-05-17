//
//  PhotoRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import Moya

final class PhotoRepository: PhotoRepositoryProtocol {
    private let provider: MoyaProvider<PhotosAPITarget>
    private let decoder: JSONDecoder

    init(provider: MoyaProvider<PhotosAPITarget>, decoder: JSONDecoder = JSONDecoder()) {
        self.provider = provider
        self.decoder = decoder
    }

    func getAllPhotos() async throws -> [Photo] {
        let response = try await provider.request(.getAllPhotos)
        let dtos = try decoder.decode([PhotoResponseDTO].self, from: response.data)
        return dtos.map { $0.toDomain() }
    }

    func deletePhoto(photoId: Int) async throws {
        _ = try await provider.request(.deletePhoto(photoId: photoId))
    }

    func uploadToS3(file: Data) async throws -> String {
        let response = try await provider.request(.s3Upload(file: file))
        let dto = try decoder.decode(S3UploadResponseDTO.self, from: response.data)
        return dto.imageUrl
    }

    func savePhotosBatch(photos: [PhotoMetadataDTO]) async throws {
        let request = PhotoBatchRequestDTO(photos: photos)
        _ = try await provider.request(.savePhotosBatch(request: request))
    }
}
