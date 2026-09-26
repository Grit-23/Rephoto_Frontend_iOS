//
//  PhotoRepository.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

final class PhotoRepository: PhotoRepositoryProtocol {
    private let adapter: NetworkAdapter
    private let decoder: JSONDecoder

    init(adapter: NetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func getAllPhotos() async throws -> [Photo] {
        let response = try await adapter.request(PhotosAPITarget.getAllPhotos)
        let dtos = try decoder.decode([PhotoResponseDTO].self, from: response.data)
        return try dtos.map { try $0.toDomain() }
    }

    func deletePhoto(photoId: Int) async throws {
        _ = try await adapter.request(PhotosAPITarget.deletePhoto(photoId: photoId))
    }

    func uploadPhotos(items: [PhotoUploadItem], onItemUploaded: (@MainActor @Sendable (Int) -> Void)?) async throws {
        guard !items.isEmpty else { return }

        let adapter = self.adapter

        let uploaded = try await withThrowingTaskGroup(of: PhotoMetadataDTO.self) { group in
            for item in items {
                group.addTask {
                    let fileData = try Data(contentsOf: item.imageUrl)
                    let response = try await adapter.request(PhotosAPITarget.s3Upload(file: fileData))
                    let dto = try JSONDecoder().decode(S3UploadResponseDTO.self, from: response.data)
                    return PhotoMetadataDTO(
                        latitude: item.latitude,
                        longitude: item.longitude,
                        imageUrl: dto.imageUrl,
                        createdAt: item.createdAt,
                        fileName: item.fileName
                    )
                }
            }

            var results: [PhotoMetadataDTO] = []
            for try await dto in group {
                results.append(dto)
                // 수집 루프는 nonisolated라 전역 executor에서 돈다 — 진행률은 UI 상태이므로 메인 액터로 넘겨 보고
                await onItemUploaded?(results.count)
            }
            return results
        }

        let request = PhotoBatchRequestDTO(photos: uploaded)
        _ = try await adapter.request(PhotosAPITarget.savePhotosBatch(request: request))
    }
}
