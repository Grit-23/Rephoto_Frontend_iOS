//
//  AlbumViewModelTests.swift
//  SearchFeatureTests
//
//  Created by Doyeon Kim on 11/10/26.
//

import Foundation
import Testing
import AlbumDomainInterface
import AlbumDomainTesting
import PhotoDomainInterface
import RephotoFoundation
@testable import SearchFeature

/// 앨범 목록과 앨범 사진의 `Loadable` 전이를 검증한다. 빈 결과와 실패가 섞이지 않아야 한다.
@Suite("AlbumViewModel")
struct AlbumViewModelTests {
    private let provider = StubSearchUseCaseProvider()

    private func makeSUT() -> AlbumViewModel {
        AlbumViewModel(provider: provider)
    }

    // MARK: - 앨범 목록

    @Test("앨범 목록 조회 성공 — loaded로 바뀐다")
    func fetchAlbumsLoads() async {
        let albums: [Album] = [.stub(tagId: 1, name: "바다", photoCount: 3), .stub(tagId: 2, name: "노을")]
        provider.getAlbums.executeHandler = { albums }
        let sut = makeSUT()

        await sut.fetchAlbums()

        #expect(sut.albums == .loaded(albums))
    }

    @Test("앨범이 없으면 실패가 아니라 빈 성공 상태다")
    func emptyAlbumsIsLoadedNotFailed() async {
        provider.getAlbums.executeHandler = { [] }
        let sut = makeSUT()

        await sut.fetchAlbums()

        #expect(sut.albums == .loaded([]))
    }

    @Test("앨범 목록 실패 — failed로 바뀐다")
    func fetchAlbumsFailure() async {
        provider.getAlbums.executeHandler = { throw NetworkError.timeout }
        let sut = makeSUT()

        await sut.fetchAlbums()

        #expect(sut.albums == .failed(.network(.timeout)))
    }

    @Test("목록이 있을 때 다시 불러오기 — loading을 거치지 않고 새 목록으로 바뀐다")
    func refetchKeepsListUntilReplaced() async {
        let first: [Album] = [.stub(tagId: 1, photoCount: 3), .stub(tagId: 2)]
        let second: [Album] = [.stub(tagId: 1, photoCount: 2)]
        let (gate, release) = AsyncStream<Void>.makeStream()
        provider.getAlbums.executeHandler = { first }
        let sut = makeSUT()
        await sut.fetchAlbums()

        provider.getAlbums.executeHandler = {
            for await _ in gate { break }
            return second
        }
        let pending = Task { await sut.fetchAlbums() }
        while provider.getAlbums.executeCallCount < 2 { await Task.yield() }

        #expect(sut.albums == .loaded(first))

        release.yield()
        release.finish()
        await pending.value

        #expect(sut.albums == .loaded(second))
    }

    @Test("목록이 있을 때 갱신 실패 — 이전 목록을 유지한다")
    func refetchFailureKeepsList() async {
        let albums: [Album] = [.stub(tagId: 1)]
        provider.getAlbums.executeHandler = { albums }
        let sut = makeSUT()
        await sut.fetchAlbums()

        provider.getAlbums.executeHandler = { throw NetworkError.timeout }
        await sut.fetchAlbums()

        #expect(sut.albums == .loaded(albums))
    }

    // MARK: - 앨범 사진

    @Test("앨범 사진 조회 — tagId를 넘기고 loaded로 바뀐다")
    func fetchAlbumPhotosLoads() async {
        let photos = [Photo.stub(photoId: 1), Photo.stub(photoId: 2)]
        provider.getAlbumPhotos.executeHandler = { _ in photos }
        let sut = makeSUT()

        await sut.fetchAlbumPhotos(tagId: 7)

        #expect(provider.getAlbumPhotos.executeArgValues == [7])
        #expect(sut.albumPhotos == .loaded(photos))
    }

    @Test("앨범 사진이 있을 때 갱신 실패 — 이전 사진 목록을 유지한다")
    func refetchAlbumPhotosFailureKeepsPhotos() async {
        let photos = [Photo.stub(photoId: 1)]
        provider.getAlbumPhotos.executeHandler = { _ in photos }
        let sut = makeSUT()
        await sut.fetchAlbumPhotos(tagId: 1)

        provider.getAlbumPhotos.executeHandler = { _ in throw NetworkError.timeout }
        await sut.fetchAlbumPhotos(tagId: 1)

        #expect(sut.albumPhotos == .loaded(photos))
    }

    @Test("앨범 사진 실패 — failed로 바뀌고 앨범 목록 상태는 건드리지 않는다")
    func fetchAlbumPhotosFailureKeepsAlbums() async {
        let albums: [Album] = [.stub(tagId: 1)]
        provider.getAlbums.executeHandler = { albums }
        provider.getAlbumPhotos.executeHandler = { _ in throw NetworkError.timeout }
        let sut = makeSUT()
        await sut.fetchAlbums()

        await sut.fetchAlbumPhotos(tagId: 1)

        #expect(sut.albumPhotos == .failed(.network(.timeout)))
        #expect(sut.albums == .loaded(albums))
    }
}
