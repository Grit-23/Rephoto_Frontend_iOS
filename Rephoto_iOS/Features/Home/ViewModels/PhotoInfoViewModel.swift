//
//  PhotoInfoViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/14/25.
//

import SwiftUI
import Moya
import Observation
import Factory

@Observable
class PhotoInfoViewModel {
    @ObservationIgnored
    @Injected(\.photosProvider) private var photoProvider
    @ObservationIgnored
    @Injected(\.tagProvider) private var provider
    @ObservationIgnored
    @Injected(\.descriptionProvider) private var descriptionProvider
    
    var isDeleted: Bool = false
    var tags: [TagResponseDto] = []   // ✅ PhotoInfoView 전용 태그 리스트
    var description: String = ""
    
    // 사진 삭제
    func deletePhoto(photoId: Int) {
        photoProvider.request(.deletePhoto(photoId: photoId)) { result in
            switch result {
            case .success(let response):
                if (200..<300).contains(response.statusCode) {
                    DispatchQueue.main.async {
                        self.isDeleted = true
                    }
                } else {
                    print("❌ failed delete status code:", response.statusCode)
                }
            case .failure(let error):
                print("❌ network error:", error)
            }
        }
    }
    
    // 태그 목록 조회
    func fetchTags(photoId: Int) {
        provider.request(.getTags(photoId: photoId)) { result in
            switch result {
            case .success(let response):
                do {
                    let dtos = try JSONDecoder().decode([TagResponseDto].self, from: response.data)
                    DispatchQueue.main.async {
                        self.tags = dtos
                    }
                } catch {
                    print("❌ decode error:", error)
                    if let raw = String(data: response.data, encoding: .utf8) {
                        print("📄 raw response:", raw) // 실제 응답 확인
                    }
                }
            case .failure(let error):
                print("❌ network error:", error)
            }
        }
    }

    
    // 태그 수정
    func updateTag(photoTagId: Int, newTagName: String) {
        guard let index = tags.firstIndex(where: { $0.photoTagId == photoTagId }) else { return }
        let oldTag = tags[index]

        // Optimistic UI
        tags[index] = TagResponseDto(
            photoTagId: oldTag.photoTagId,
            tagId: oldTag.tagId,
            tagName: newTagName,
            photoId: oldTag.photoId
        )

        let request = TagRequestDto(tagName: newTagName)
        provider.request(.updateTag(photoTagId: photoTagId, tagName: request.tagName)) { result in
            switch result {
            case .success(let response):
                do {
                    let dtos = try JSONDecoder().decode(TagResponseDto.self, from: response.data) // ✅ 배열 디코딩
                    DispatchQueue.main.async {
                        self.tags[index] = dtos   // 서버가 내려준 최신 리스트 전체로 교체
                    }
                } catch {
                    print("❌ decode error:", error)
                }
            case .failure(let error):
                print("❌ network error:", error)
                DispatchQueue.main.async { self.tags[index] = oldTag }
            }
        }
    }
    
    // 태그 추가
    func addTag(photoId: Int, tagName: String) {
        provider.request(.addTag(photoId: photoId, tagName: tagName)) { result in
            switch result {
            case .success(let response):
                do {
                    let dto = try JSONDecoder().decode(TagResponseDto.self, from: response.data) // ✅ 배열 디코딩
                    DispatchQueue.main.async {
                        self.tags.append(dto)
                    }
                } catch {
                    print("❌ decode error:", error)
                }
            case .failure(let error):
                print("❌ network error:", error)
            }
        }
    }
    
    func getDescription(photoId: Int) {
        descriptionProvider.request(.description(photoId: photoId)) { result in
            switch result {
            case .success(let response):
                do {
                    let text = try response.mapString().trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async {
                        self.description = text
                    }
                } catch {
                    print("❌ decode error:", error)
                }
            case .failure(let error):
                print("❌ network error:", error)
            }
        }
    }
}
