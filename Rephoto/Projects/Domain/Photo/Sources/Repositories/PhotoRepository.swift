//
//  PhotoRepository.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import NetworkAdapter
import PhotoDomainInterface

/// Approachable Concurrency에서는 nonisolated async가 호출자 액터에서 돌므로,
/// 목록 디코딩이 메인 액터 위에서 실행되지 않도록 `@concurrent`로 내보낸다.
/// 업로드는 장별 작업이 TaskGroup 자식 Task로 이미 전역 실행자에서 돈다.
public final class PhotoRepository: PhotoRepositoryProtocol, Sendable {
    private let adapter: NetworkAdapter
    private let decoder: JSONDecoder

    public init(adapter: NetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    @concurrent
    public func getAllPhotos() async throws -> [Photo] {
        let data = try await adapter.request(PhotosAPITarget.getAllPhotos)
        let dtos = try decoder.decode([PhotoResponseDTO].self, from: data)
        return try dtos.map { try $0.toDomain() }
    }

    public func deletePhoto(photoId: Int) async throws {
        _ = try await adapter.request(PhotosAPITarget.deletePhoto(photoId: photoId))
    }

    public func uploadPhotos(items: [PhotoUploadItem], onItemUploaded: (@MainActor @Sendable (Int) -> Void)?) async throws {
        guard !items.isEmpty else { return }

        let adapter = self.adapter
        let decoder = self.decoder

        let uploaded = try await withThrowingTaskGroup(of: PhotoMetadataDTO.self) { group in
            for item in items {
                group.addTask {
                    let fileData = try Data(contentsOf: item.imageUrl)
                    let data = try await adapter.request(PhotosAPITarget.s3Upload(file: fileData))
                    let dto = try decoder.decode(S3UploadResponseDTO.self, from: data)
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
                // 진행률은 UI 상태이므로 메인 액터로 넘겨 보고
                await onItemUploaded?(results.count)
            }
            return results
        }

        let request = PhotoBatchRequestDTO(photos: uploaded)
        _ = try await adapter.request(PhotosAPITarget.savePhotosBatch(request: request))
    }
}
