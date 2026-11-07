//
//  HomeViewModel.swift
//  HomeFeature
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI
import PhotosUI
import DesignSystem
import PhotoDomainInterface
import RephotoFoundation

@Observable
final class HomeViewModel {
    let provider: any HomeUseCaseProviderProtocol
    /// 업로드처럼 작업 흐름이 끊기는 실패를 전역 Alert으로 넘기는 창구.
    private let errorHandler: ErrorHandler

    struct UploadProgress: Equatable {
        var completed: Int
        var total: Int
    }

    /// 목록 조회 상태. 사진이 없을 때의 실패만 `.failed`로 화면을 채우고,
    /// 사진이 있으면 상태를 유지한 채 Alert으로만 알린다.
    ///
    /// 파생 컬렉션은 계산 프로퍼티 대신 didSet 캐싱 — body 평가마다 filter 재실행 방지,
    /// 관찰 의존성을 photos 전체가 아닌 파생 배열로 좁힘
    private(set) var photos: Loadable<[Photo]> = .idle {
        didSet {
            let loaded = photos.value ?? []
            visiblePhotos = loaded.filter { !$0.isSensitive }
            sensitivePhotos = loaded.filter(\.isSensitive)
            sensitiveCount = sensitivePhotos.count
            hasPhotos = !loaded.isEmpty
        }
    }
    private(set) var visiblePhotos: [Photo] = []
    private(set) var sensitivePhotos: [Photo] = []
    private(set) var sensitiveCount: Int = 0
    /// 뷰가 `photos`를 직접 읽지 않고 "사진이 있는가"만 알 수 있게 캐싱한다.
    /// 계산 프로퍼티에서 `photos`를 읽으면 관찰 의존성이 배열 전체로 전이되어,
    /// 파생 컬렉션을 캐싱해 좁혀둔 무효화 범위가 다시 넓어진다.
    private(set) var hasPhotos: Bool = false
    private(set) var uploadProgress: UploadProgress?

    init(provider: any HomeUseCaseProviderProtocol, errorHandler: ErrorHandler) {
        self.provider = provider
        self.errorHandler = errorHandler
    }

    func fetchPhotos() async {
        // 이미 보여줄 사진이 있으면 화면을 비우지 않는다
        let previous = photos
        if !hasPhotos {
            photos = .loading
        }
        do {
            photos = .loaded(try await provider.makeGetPhotosUseCase().execute())
        } catch {
            guard !error.isCancellation else {
                if !hasPhotos {
                    photos = previous
                }
                return
            }
            let appError = AppError.from(error)
            if hasPhotos {
                errorHandler.handle(appError, retry: { [weak self] in await self?.fetchPhotos() })
            } else {
                photos = .failed(appError)
            }
        }
    }

    func handlePickedPhotos(_ pickerItems: [PhotosPickerItem]) async {
        guard !pickerItems.isEmpty else { return }
        // 업로드 진행 중 재선택 시 중복 실행 방지 — 먼저 끝난 쪽의 defer가
        // 진행 중인 배너 상태를 지워버리는 충돌을 막는다
        guard uploadProgress == nil else { return }
        uploadProgress = UploadProgress(completed: 0, total: pickerItems.count)
        defer { uploadProgress = nil }

        let extractUseCase = provider.makeExtractPhotoMetadataUseCase()
        let items = await withTaskGroup(of: PhotoUploadItem?.self, returning: [PhotoUploadItem].self) { group in
            for pickerItem in pickerItems {
                group.addTask {
                    // PhotosPickerItem(SwiftUI) → Data 변환까지만 Presentation이 담당하고,
                    // 메타데이터 추출/압축은 Domain 계약(UseCase) 뒤의 구현체가 수행
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
            // 업로드 실패는 사용자가 시작한 작업이 끊긴 경우 — 전역 Alert + 재시도
            errorHandler.handle(error, retry: { [weak self] in await self?.handlePickedPhotos(pickerItems) })
        }
    }
}
