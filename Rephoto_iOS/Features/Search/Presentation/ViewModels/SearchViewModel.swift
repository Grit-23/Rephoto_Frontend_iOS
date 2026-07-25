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
    /// 요청 세대 — 상태(결과/에러/로딩) 변경을 가장 최근 요청에만 귀속시킨다
    private var searchGeneration = 0
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var query: String = ""

    init(provider: SearchUseCaseProviderProtocol, getPhotosUseCase: GetPhotosUseCaseProtocol) {
        self.provider = provider
        self.getPhotosUseCase = getPhotosUseCase
    }

    @MainActor
    func search(query: String) async {
        searchGeneration += 1
        let generation = searchGeneration
        isLoading = true
        errorMessage = nil

        do {
            let results = try await provider.searchPhotos().execute(query: query)
            // 검색어가 바뀌어 교체/취소된 요청이면 늦게 도착한 결과로 상태를 덮어쓰지 않는다
            guard generation == searchGeneration, !Task.isCancelled else { return }
            searchResults = results
            isLoading = false
        } catch {
            // 취소는 CancellationError 외에 URLError(.cancelled) 등으로도 던져진다 —
            // 교체/취소된 요청의 실패는 최신 요청의 상태를 건드리지 않는다
            guard generation == searchGeneration, !Task.isCancelled, !(error is CancellationError) else { return }
            searchResults = []
            errorMessage = error.localizedDescription
            isLoading = false
        }

        // 이전에 색인 로드가 실패했다면 결과 → 상세 매핑을 위해 재시도
        // (결과 반영·로딩 종료 후에 수행 — 재시도 동안 스피너를 붙잡지 않는다)
        if photoIndexLoadFailed {
            await loadPhotoIndex()
        }
    }

    @MainActor
    func clearResults() {
        searchGeneration += 1  // 진행 중 요청 무효화
        searchResults = []
        errorMessage = nil
        isLoading = false
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
