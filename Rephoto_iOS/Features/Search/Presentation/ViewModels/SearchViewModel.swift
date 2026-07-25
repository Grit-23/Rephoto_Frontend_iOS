//
//  SearchViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

@Observable
final class SearchViewModel {
    let provider: SearchUseCaseProviderProtocol
    private let getPhotosUseCase: GetPhotosUseCaseProtocol

    private(set) var searchResults: [SearchResult] = []
    /// 검색 결과(photoId)를 사진 상세용 전체 Photo로 매핑하기 위한 홈 사진 색인
    private(set) var photosById: [Int: Photo] = [:]
    /// 색인 로드 실패 여부 — 다음 검색 시 재시도 트리거로 사용
    private var photoIndexLoadFailed = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var query: String = ""

    init(provider: SearchUseCaseProviderProtocol, getPhotosUseCase: GetPhotosUseCaseProtocol) {
        self.provider = provider
        self.getPhotosUseCase = getPhotosUseCase
    }

    @MainActor
    func search(query: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let results = try await provider.searchPhotos().execute(query: query)
            // 검색어가 바뀌어 이 작업이 취소됐다면 늦게 도착한 결과로 최신 결과를 덮어쓰지 않는다
            guard !Task.isCancelled else { return }
            searchResults = results
        } catch is CancellationError {
            return
        } catch {
            searchResults = []
            errorMessage = error.localizedDescription
        }

        // 이전에 색인 로드가 실패했다면 결과 → 상세 매핑을 위해 재시도
        if photoIndexLoadFailed {
            await loadPhotoIndex()
        }
    }

    @MainActor
    func clearResults() {
        searchResults = []
        errorMessage = nil
    }

    @MainActor
    func loadPhotoIndex() async {
        do {
            let photos = try await getPhotosUseCase.execute()
            photosById = Dictionary(photos.map { ($0.photoId, $0) }, uniquingKeysWith: { first, _ in first })
            photoIndexLoadFailed = false
        } catch is CancellationError {
            // 화면 이탈 등으로 취소된 경우는 실패로 취급하지 않음
        } catch {
            // 색인은 상세 화면 메타데이터 보강용 — 실패해도 검색과 상세 진입은
            // 폴백 Photo로 동작하므로 별도 에러 노출 없이 다음 검색 시 재시도한다
            photoIndexLoadFailed = true
        }
    }
}
