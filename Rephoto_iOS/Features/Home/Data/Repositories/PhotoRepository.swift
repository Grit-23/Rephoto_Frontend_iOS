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
        return try dtos.map { try $0.toDomain() }
    }

    func deletePhoto(photoId: Int) async throws {
        _ = try await provider.request(.deletePhoto(photoId: photoId))
    }

    func uploadPhotos(items: [PhotoUploadItem]) async throws {
        var uploaded: [PhotoMetadataDTO] = []

        for item in items {
            guard let fileData = try? Data(contentsOf: URL(string: item.imageUrl)!) else { continue }
            let response = try await provider.request(.s3Upload(file: fileData))
            let dto = try decoder.decode(S3UploadResponseDTO.self, from: response.data)
            let meta = PhotoMetadataDTO(
                latitude: item.latitude,
                longitude: item.longitude,
                imageUrl: dto.imageUrl,
                createdAt: item.createdAt,
                fileName: item.fileName
            )
            uploaded.append(meta)
        }

        guard !uploaded.isEmpty else { return }
        let request = PhotoBatchRequestDTO(photos: uploaded)
        _ = try await provider.request(.savePhotosBatch(request: request))
    }
}
