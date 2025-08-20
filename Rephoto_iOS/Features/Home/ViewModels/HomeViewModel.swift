//
//  HomeViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import Observation
import Moya
import PhotosUI
import Photos
import UIKit

@Observable
class HomeViewModel {
    var images: [HomeModel] = []
    var imageUrl: String = ""
    
    var isWarningsCount: Int { images.count(where: { $0.isSensitive }) }
    
    private let provider = MoyaProvider<PhotosAPITarget>()
    
    init() {
        fetchPhotos()
    }
    
    // MARK: - 목록 조회 (콜백)
    func fetchPhotos() {
        provider.request(.getAllPhotos) { result in
            switch result {
            case .success(let response):
                do {
                    let dtos = try JSONDecoder().decode([PhotoResponseDto].self, from: response.data)
                    let mapped = dtos.map { $0.toHomeModel() }
                    DispatchQueue.main.async { self.images = mapped }
                } catch {
                    self.images.removeAll()
                }
            case .failure(let error):
                print("❌ network error:", error)
            }
        }
    }
    
    // MARK: - 선택 → 업로드 → 배치 저장
    func handlePickedItems(items: [PhotoMetadata]) {
        guard !items.isEmpty else { return }
        
        var uploaded: [PhotoMetadata] = []
        let group = DispatchGroup()
        
        for item in items {
            group.enter()
            
            // 파일 URL에서 Data 읽기
            if let fileData = try? Data(contentsOf: URL(string: item.imageUrl)!) {
                // 1. S3 업로드
                uploadS3ForURL(file: fileData) { result in
                    switch result {
                    case .success(let urlString):
                        // 2. 업로드 성공 → 서버에서 받은 URL로 PhotoMetadata 생성
                        let meta = PhotoMetadata(
                            latitude: item.latitude,
                            longitude: item.longitude,
                            imageUrl: urlString,  // S3 URL 대체
                            createdAt: item.createdAt,
                            fileName: item.fileName
                        )
                        uploaded.append(meta)
                        
                    case .failure(let error):
                        print("❌ 업로드 실패:", error)
                    }
                    group.leave()
                }
            } else {
                print("❌ 파일 데이터를 불러올 수 없음:", item.fileName)
                group.leave()
            }
        }
        
        // 3. 모든 업로드가 끝나면 일괄 저장
        group.notify(queue: .main) {
            guard !uploaded.isEmpty else { return }
            self.saveBatch(photos: uploaded) { result in
                switch result {
                case .success:
                    print("✅ 서버에 사진 일괄 저장 성공")
                    self.fetchPhotos() // 저장 후 목록 갱신
                case .failure(let error):
                    print("❌ 저장 실패:", error)
                }
            }
        }
    }

    /// S3 업로드 후 URL 반환 (콜백)
    private func uploadS3ForURL(file: Data,
                                completion: @escaping (Result<String, Error>) -> Void) {
        provider.request(.s3Upload(file: file)) { result in
            switch result {
            case .success(let response):
                print(response.data)
                do {
                    let dto = try JSONDecoder().decode(S3UploadResponseDto.self, from: response.data)
                    completion(.success(dto.url))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 배치 저장 (콜백)
    private func saveBatch(photos: [PhotoMetadata],
                           completion: @escaping (Result<Void, Error>) -> Void) {
        let req = PhotoBatchRequestDto(photos: photos)
        provider.request(.savePhotosBatch(request: req)) { result in
            switch result {
            case .success(let response):
                print("📦 saveBatch Response: \(response.statusCode)")
            case .failure(let error):
                print("❌ saveBatch Network Error:", error)
            }
        }
    }

}
