//
//  PhotoInfoViewModelTests.swift
//  HomeFeatureTests
//
//  Created by Doyeon Kim on 11/6/26.
//

import Foundation
import Testing
import DesignSystem
import PhotoDomainTesting
import RephotoFoundation
import TagDomainInterface
import TagDomainTesting
@testable import HomeFeature

/// 태그 편집 결과가 로컬 목록에 반영되는지와, 실패가 전역 Alert으로 가는지를 검증한다.
@Suite("PhotoInfoViewModel")
struct PhotoInfoViewModelTests {
    private let provider = StubHomeUseCaseProvider()
    private let errorHandler = ErrorHandler()

    private func makeSUT() -> PhotoInfoViewModel {
        PhotoInfoViewModel(provider: provider, errorHandler: errorHandler)
    }

    // MARK: - 태그

    @Test("태그 조회 — 사진 id로 요청하고 목록을 채운다")
    func fetchTagsFillsList() async {
        provider.getTags.executeHandler = { _ in [.stub(photoTagId: 11, name: "바다"), .stub(photoTagId: 12, name: "노을")] }
        let sut = makeSUT()

        await sut.fetchTags(photoId: 1)

        #expect(provider.getTags.executeArgValues == [1])
        #expect(sut.tags.map(\.tagName) == ["바다", "노을"])
    }

    @Test("태그 추가 — 서버가 돌려준 태그를 목록 끝에 붙인다")
    func addTagAppends() async {
        provider.getTags.executeHandler = { _ in [.stub(photoTagId: 11, name: "바다")] }
        provider.addTag.executeHandler = { photoId, name in .stub(photoTagId: 99, name: name, photoId: photoId) }
        let sut = makeSUT()
        await sut.fetchTags(photoId: 1)

        await sut.addTag(photoId: 1, tagName: "노을")

        #expect(sut.tags.map(\.photoTagId) == [11, 99])
        #expect(sut.tags.last?.tagName == "노을")
    }

    @Test("태그가 이미 3개면 추가 요청을 보내지 않는다")
    func addTagRespectsLimit() async {
        provider.getTags.executeHandler = { _ in
            [.stub(photoTagId: 11, name: "바다"), .stub(photoTagId: 12, name: "노을"), .stub(photoTagId: 13, name: "산책")]
        }
        let sut = makeSUT()
        await sut.fetchTags(photoId: 1)

        await sut.addTag(photoId: 1, tagName: "봄")

        #expect(!sut.canAddTag)
        #expect(provider.addTag.executeCallCount == 0)
        #expect(sut.tags.count == 3)
    }

    @Test("응답을 기다리는 추가 요청도 개수 제한에 포함한다")
    func pendingAddCountsTowardLimit() async {
        provider.getTags.executeHandler = { _ in [.stub(photoTagId: 11, name: "바다"), .stub(photoTagId: 12, name: "노을")] }
        let (gate, release) = AsyncStream<Void>.makeStream()
        provider.addTag.executeHandler = { photoId, name in
            for await _ in gate { break }
            return .stub(photoTagId: 99, name: name, photoId: photoId)
        }
        let sut = makeSUT()
        await sut.fetchTags(photoId: 1)

        let first = Task { await sut.addTag(photoId: 1, tagName: "산책") }
        while sut.pendingAddCount == 0 { await Task.yield() }

        #expect(!sut.canAddTag)
        await sut.addTag(photoId: 1, tagName: "봄")

        release.yield()
        release.finish()
        await first.value

        #expect(provider.addTag.executeCallCount == 1)
        #expect(sut.tags.map(\.tagName) == ["바다", "노을", "산책"])
        #expect(sut.pendingAddCount == 0)
    }

    @Test("태그 수정 — 같은 id의 항목만 제자리에서 바꾼다")
    func updateTagReplacesInPlace() async {
        provider.getTags.executeHandler = { _ in [.stub(photoTagId: 11, name: "바다"), .stub(photoTagId: 12, name: "노을")] }
        provider.updateTag.executeHandler = { id, name in .stub(photoTagId: id, name: name) }
        let sut = makeSUT()
        await sut.fetchTags(photoId: 1)

        await sut.updateTag(photoTagId: 12, newTagName: "석양")

        #expect(sut.tags.map(\.tagName) == ["바다", "석양"])
    }

    @Test("태그 삭제 — 목록에서 제거한다")
    func deleteTagRemoves() async {
        provider.getTags.executeHandler = { _ in [.stub(photoTagId: 11, name: "바다"), .stub(photoTagId: 12, name: "노을")] }
        provider.deleteTag.executeHandler = { _ in }
        let sut = makeSUT()
        await sut.fetchTags(photoId: 1)

        await sut.deleteTag(photoTagId: 11)

        #expect(provider.deleteTag.executeArgValues == [11])
        #expect(sut.tags.map(\.photoTagId) == [12])
    }

    @Test("태그 추가 실패 — 목록은 그대로 두고 Alert으로 알린다")
    func addTagFailureAlerts() async {
        provider.addTag.executeHandler = { _, _ in throw NetworkError.httpError(statusCode: 500, data: Data()) }
        let sut = makeSUT()

        await sut.addTag(photoId: 1, tagName: "노을")

        #expect(sut.tags.isEmpty)
        #expect(errorHandler.currentError == .network(.httpError(statusCode: 500, data: Data())))
        #expect(errorHandler.showRetry)
    }

    // MARK: - 설명 · 삭제

    @Test("AI 설명 조회 결과를 보관한다")
    func getDescriptionStoresText() async {
        provider.getDescription.executeHandler = { _ in "해 질 녘 풍경" }
        let sut = makeSUT()

        await sut.getDescription(photoId: 1)

        #expect(sut.description == "해 질 녘 풍경")
    }

    @Test("사진 삭제 성공 — isDeleted가 켜진다")
    func deletePhotoSetsFlag() async {
        provider.deletePhoto.executeHandler = { _ in }
        let sut = makeSUT()

        await sut.deletePhoto(photoId: 1)

        #expect(provider.deletePhoto.executeArgValues == [1])
        #expect(sut.isDeleted)
    }

    @Test("사진 삭제 실패 — isDeleted는 꺼진 채 Alert으로 알린다")
    func deletePhotoFailureAlerts() async {
        provider.deletePhoto.executeHandler = { _ in throw NetworkError.timeout }
        let sut = makeSUT()

        await sut.deletePhoto(photoId: 1)

        #expect(!sut.isDeleted)
        #expect(errorHandler.currentError == .network(.timeout))
    }
}
