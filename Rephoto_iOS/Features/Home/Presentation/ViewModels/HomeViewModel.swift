//
//  HomeViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI
import PhotosUI

@Observable
final class HomeViewModel {
    let provider: HomeUseCaseProviderProtocol

    struct UploadProgress: Equatable {
        var completed: Int
        var total: Int
    }

    // 파생 컬렉션은 계산 프로퍼티 대신 didSet 캐싱 — body 평가마다 filter 재실행 방지,
    // 관찰 의존성을 photos 전체가 아닌 파생 배열로 좁힘
    private(set) var photos: [Photo] = [] {
        didSet {
            visiblePhotos = photos.filter { !$0.isSensitive }
            sensitivePhotos = photos.filter(\.isSensitive)
            sensitiveCount = sensitivePhotos.count
        }
    }
    private(set) var visiblePhotos: [Photo] = []
    private(set) var sensitivePhotos: [Photo] = []
    private(set) var sensitiveCount: Int = 0
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var uploadProgress: UploadProgress?

    // 사진이 있는 상태의 실패(업로드 등)만 알림으로 표시 — 빈 화면 에러는 전체 화면 상태가 담당.
    // KeyPath 기반 Binding($vm.isShowingErrorAlert)으로 쓰기 위한 양방향 프로퍼티
    var isShowingErrorAlert: Bool {
        get { errorMessage != nil && !photos.isEmpty }
        set { if !newValue { errorMessage = nil } }
    }

    init(provider: HomeUseCaseProviderProtocol) {
        self.provider = provider
    }

    @MainActor
    func fetchPhotos() async {
        isLoading = true
        errorMessage = nil
        do {
            photos = try await provider.makeGetPhotosUseCase().execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func handlePickedPhotos(_ pickerItems: [PhotosPickerItem]) async {
        guard !pickerItems.isEmpty else { return }
        // 업로드 진행 중 재선택 시 중복 실행 방지 — 먼저 끝난 쪽의 defer가
        // 진행 중인 배너 상태를 지워버리는 충돌을 막는다
        guard uploadProgress == nil else { return }
        errorMessage = nil
        uploadProgress = UploadProgress(completed: 0, total: pickerItems.count)
        defer { uploadProgress = nil }

        let extractUseCase = provider.makeExtractPhotoMetadataUseCase()
        let items = await withTaskGroup(of: PhotoUploadItem?.self, returning: [PhotoUploadItem].self) { group in
            for pickerItem in pickerItems {
                group.addTask {
                    // PhotosPickerItem(SwiftUI) → Data 변환까지만 Presentation이 담당하고,
                    // 메타데이터 추출/압축은 Domain 계약(UseCase) 뒤의 Data 구현체가 수행
                    guard let data = try? await pickerItem.loadTransferable(type: Data.self) else {
                        return nil
                    }
                    return await extractUseCase.execute(imageData: data, identifier: pickerItem.itemIdentifier)
                }
            }
            var results: [PhotoUploadItem] = []
            for await item in group {
                if let item { results.append(item) }
            }
            return results
        }

        guard !items.isEmpty else { return }

        do {
            try await provider.makeUploadPhotosUseCase().execute(items: items) { [weak self] completed in
                self?.uploadProgress?.completed = completed
            }
            await fetchPhotos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
