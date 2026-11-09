//
//  HomeViewModelTests.swift
//  HomeFeatureTests
//
//  Created by Doyeon Kim on 11/6/26.
//

import Foundation
import Testing
import DesignSystem
import PhotoDomainInterface
import PhotoDomainTesting
import RephotoFoundation
@testable import HomeFeature

/// 목록 상태(`Loadable`) 전이와, 사진이 있을 때의 실패를 Alert으로만 알리는 규칙을 검증한다.
@Suite("HomeViewModel")
struct HomeViewModelTests {
    private let provider = StubHomeUseCaseProvider()
    private let errorHandler = ErrorHandler()

    private func makeSUT() -> HomeViewModel {
        HomeViewModel(provider: provider, errorHandler: errorHandler)
    }

    // MARK: - 목록

    @Test("조회 성공 — loaded로 바뀌고 민감 사진은 파생 컬렉션으로 갈라진다")
    func fetchSplitsSensitivePhotos() async {
        let photos: [Photo] = [.stub(photoId: 1), .stub(photoId: 2, isSensitive: true), .stub(photoId: 3)]
        provider.getPhotos.executeHandler = { photos }
        let sut = makeSUT()

        await sut.fetchPhotos()

        #expect(sut.photos == .loaded(photos))
        #expect(sut.visiblePhotos.map(\.photoId) == [1, 3])
        #expect(sut.sensitivePhotos.map(\.photoId) == [2])
        #expect(sut.sensitiveCount == 1)
        #expect(sut.hasPhotos)
    }

    @Test("빈 목록은 실패가 아니라 빈 성공 상태다")
    func emptyListIsLoadedNotFailed() async {
        provider.getPhotos.executeHandler = { [] }
        let sut = makeSUT()

        await sut.fetchPhotos()

        #expect(sut.photos == .loaded([]))
        #expect(!sut.hasPhotos)
        #expect(errorHandler.currentError == nil)
    }

    // MARK: - 실패

    @Test("사진이 없을 때 실패 — failed로 화면을 채우고 Alert은 띄우지 않는다")
    func failureWithoutPhotosBecomesFailedState() async {
        provider.getPhotos.executeHandler = { throw NetworkError.timeout }
        let sut = makeSUT()

        await sut.fetchPhotos()

        #expect(sut.photos == .failed(.network(.timeout)))
        #expect(sut.visiblePhotos.isEmpty)
        #expect(errorHandler.currentError == nil)
    }

    @Test("사진이 있을 때 실패 — 목록을 유지하고 재시도 가능한 Alert으로만 알린다")
    func failureWithPhotosKeepsListAndAlerts() async {
        let photos = [Photo.stub(photoId: 1)]
        provider.getPhotos.executeHandler = { photos }
        let sut = makeSUT()
        await sut.fetchPhotos()

        provider.getPhotos.executeHandler = { throw NetworkError.timeout }
        await sut.fetchPhotos()

        #expect(sut.photos == .loaded(photos))
        #expect(sut.visiblePhotos.map(\.photoId) == [1])
        #expect(errorHandler.currentError == .network(.timeout))
        #expect(errorHandler.showRetry)
    }

    @Test("취소는 실패로 바꾸지 않고 이전 상태로 돌아간다")
    func cancellationRestoresPreviousState() async {
        provider.getPhotos.executeHandler = { throw CancellationError() }
        let sut = makeSUT()

        await sut.fetchPhotos()

        #expect(sut.photos == .idle)
        #expect(errorHandler.currentError == nil)
    }

    @Test("실패 뒤 재시도 성공 — failed에서 loaded로 돌아온다")
    func retryAfterFailureLoads() async {
        provider.getPhotos.executeHandler = { throw NetworkError.timeout }
        let sut = makeSUT()
        await sut.fetchPhotos()

        let photos = [Photo.stub(photoId: 1)]
        provider.getPhotos.executeHandler = { photos }
        await sut.fetchPhotos()

        #expect(sut.photos == .loaded(photos))
        #expect(provider.getPhotos.executeCallCount == 2)
    }

    // MARK: - 업로드

    @Test("빈 선택은 추출 · 업로드를 호출하지 않는다")
    func emptySelectionIsNoOp() async {
        let sut = makeSUT()

        await sut.handlePickedPhotos([])

        #expect(provider.extractMetadata.executeCallCount == 0)
        #expect(provider.uploadPhotos.executeCallCount == 0)
        #expect(sut.uploadProgress == nil)
    }
}
