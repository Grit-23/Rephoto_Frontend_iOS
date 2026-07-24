//
//  SearchViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

@Observable
class SearchViewModel {
    let provider: SearchUseCaseProviderProtocol
    private let getPhotosUseCase: GetPhotosUseCaseProtocol

    var searchResults: [SearchResult] = []
    /// 검색 결과(photoId)를 사진 상세용 전체 Photo로 매핑하기 위한 홈 사진 색인
    private(set) var photosById: [Int: Photo] = [:]
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
        do {
            searchResults = try await provider.searchPhotos().execute(query: query)
        } catch {
            searchResults = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func loadPhotoIndex() async {
        guard let photos = try? await getPhotosUseCase.execute() else { return }
        photosById = Dictionary(photos.map { ($0.photoId, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
