//
//  SearchViewModelTests.swift
//  SearchFeatureTests
//
//  Created by Doyeon Kim on 11/10/26.
//

import Foundation
import Testing
import PhotoDomainInterface
import PhotoDomainTesting
import RephotoFoundation
@testable import SearchFeature

/// 검색 상태(`Loadable`) 전이, 늦게 도착한 결과를 버리는 세대 검사, 색인 실패 시 폴백과 재시도를 검증한다.
@Suite("SearchViewModel")
struct SearchViewModelTests {
    private let provider = StubSearchUseCaseProvider()

    private func makeSUT() -> SearchViewModel {
        SearchViewModel(provider: provider)
    }

    // MARK: - 검색

    @Test("검색 성공 — 검색어를 그대로 넘기고 loaded로 바뀐다")
    func searchLoadsResults() async {
        let results: [SearchResult] = [.stub(photoId: 1), .stub(photoId: 2)]
        provider.search.executeHandler = { _ in results }
        let sut = makeSUT()

        await sut.search(query: "바다")

        #expect(provider.search.executeArgValues == ["바다"])
        #expect(sut.searchResults == .loaded(results))
    }

    @Test("빈 결과는 실패가 아니라 빈 성공 상태다")
    func emptyResultIsLoadedNotFailed() async {
        provider.search.executeHandler = { _ in [] }
        let sut = makeSUT()

        await sut.search(query: "없는태그")

        #expect(sut.searchResults == .loaded([]))
    }

    @Test("검색 실패 — failed로 바뀐다")
    func failureBecomesFailedState() async {
        provider.search.executeHandler = { _ in throw NetworkError.timeout }
        let sut = makeSUT()

        await sut.search(query: "바다")

        #expect(sut.searchResults == .failed(.network(.timeout)))
    }

    @Test("초기화 뒤 늦게 도착한 결과는 상태를 덮어쓰지 않는다")
    func clearIgnoresLateResult() async {
        let (gate, release) = AsyncStream<Void>.makeStream()
        provider.search.executeHandler = { _ in
            for await _ in gate { break }
            return [.stub(photoId: 1)]
        }
        let sut = makeSUT()

        let pending = Task { await sut.search(query: "바다") }
        while provider.search.executeCallCount == 0 { await Task.yield() }
        sut.clearResults()

        release.yield()
        release.finish()
        await pending.value

        #expect(sut.searchResults == .idle)
    }

    @Test("검색어가 바뀌어 교체된 요청의 결과는 최신 결과를 덮어쓰지 않는다")
    func replacedSearchIgnoresLateResult() async {
        let (gate, release) = AsyncStream<Void>.makeStream()
        let latest: [SearchResult] = [.stub(photoId: 2)]
        provider.search.executeHandler = { query in
            guard query == "바" else { return latest }
            for await _ in gate { break }
            return [.stub(photoId: 1)]
        }
        let sut = makeSUT()

        let first = Task { await sut.search(query: "바") }
        while provider.search.executeCallCount == 0 { await Task.yield() }
        await sut.search(query: "바다")

        release.yield()
        release.finish()
        await first.value

        #expect(sut.searchResults == .loaded(latest))
    }

    // MARK: - 같은 검색어 재요청

    @Test("같은 검색어 재요청 — loading을 거치지 않고 새 결과로 바뀐다")
    func sameQueryRefetchKeepsResultsUntilReplaced() async {
        let first: [SearchResult] = [.stub(photoId: 1), .stub(photoId: 2)]
        let second: [SearchResult] = [.stub(photoId: 2)]
        let (gate, release) = AsyncStream<Void>.makeStream()
        provider.search.executeHandler = { _ in first }
        let sut = makeSUT()
        await sut.search(query: "바다")

        provider.search.executeHandler = { _ in
            for await _ in gate { break }
            return second
        }
        let pending = Task { await sut.search(query: "바다") }
        while provider.search.executeCallCount < 2 { await Task.yield() }

        #expect(sut.searchResults == .loaded(first))

        release.yield()
        release.finish()
        await pending.value

        #expect(sut.searchResults == .loaded(second))
    }

    @Test("같은 검색어 재요청 실패 — 이전 결과를 유지한다")
    func sameQueryRefetchFailureKeepsResults() async {
        let results: [SearchResult] = [.stub(photoId: 1)]
        provider.search.executeHandler = { _ in results }
        let sut = makeSUT()
        await sut.search(query: "바다")

        provider.search.executeHandler = { _ in throw NetworkError.timeout }
        await sut.search(query: "바다")

        #expect(sut.searchResults == .loaded(results))
    }

    @Test("다른 검색어 요청 — 이전 결과를 지우고 loading으로 바뀐다")
    func differentQueryShowsLoading() async {
        let (gate, release) = AsyncStream<Void>.makeStream()
        provider.search.executeHandler = { _ in [.stub(photoId: 1)] }
        let sut = makeSUT()
        await sut.search(query: "바다")

        provider.search.executeHandler = { _ in
            for await _ in gate { break }
            return []
        }
        let pending = Task { await sut.search(query: "노을") }
        while provider.search.executeCallCount < 2 { await Task.yield() }

        #expect(sut.searchResults == .loading)

        release.yield()
        release.finish()
        await pending.value

        #expect(sut.searchResults == .loaded([]))
    }

    @Test("초기화 뒤 같은 검색어 — 이전 결과가 없으므로 loading부터 시작한다")
    func clearResetsRefreshTracking() async {
        let (gate, release) = AsyncStream<Void>.makeStream()
        provider.search.executeHandler = { _ in [.stub(photoId: 1)] }
        let sut = makeSUT()
        await sut.search(query: "바다")
        sut.clearResults()

        provider.search.executeHandler = { _ in
            for await _ in gate { break }
            return [.stub(photoId: 1)]
        }
        let pending = Task { await sut.search(query: "바다") }
        while provider.search.executeCallCount < 2 { await Task.yield() }

        #expect(sut.searchResults == .loading)

        release.yield()
        release.finish()
        await pending.value
    }

    // MARK: - 색인

    @Test("색인 성공 — photoId로 찾을 수 있고 다음 검색에서 다시 부르지 않는다")
    func indexBuildsLookupOnce() async {
        provider.getPhotos.executeHandler = { [.stub(photoId: 1), .stub(photoId: 2)] }
        provider.search.executeHandler = { _ in [.stub(photoId: 1)] }
        let sut = makeSUT()

        await sut.loadPhotoIndex()
        await sut.search(query: "바다")

        #expect(sut.photosById.keys.sorted() == [1, 2])
        #expect(sut.photosById[1] == .stub(photoId: 1))
        #expect(provider.getPhotos.executeCallCount == 1)
    }

    @Test("색인 실패 — 에러를 드러내지 않고 다음 검색 뒤에 다시 시도한다")
    func indexFailureFallsBackAndRetriesAfterSearch() async {
        provider.getPhotos.executeHandler = { throw NetworkError.timeout }
        let sut = makeSUT()

        await sut.loadPhotoIndex()

        #expect(sut.photosById.isEmpty)
        #expect(sut.searchResults == .idle)

        provider.getPhotos.executeHandler = { [.stub(photoId: 1)] }
        provider.search.executeHandler = { _ in [.stub(photoId: 1)] }
        await sut.search(query: "바다")

        #expect(sut.searchResults == .loaded([.stub(photoId: 1)]))
        #expect(provider.getPhotos.executeCallCount == 2)
        #expect(sut.photosById[1] == .stub(photoId: 1))
    }

    @Test("색인 취소는 실패로 치지 않아 다음 검색에서 재시도하지 않는다")
    func indexCancellationDoesNotScheduleRetry() async {
        provider.getPhotos.executeHandler = { throw CancellationError() }
        provider.search.executeHandler = { _ in [] }
        let sut = makeSUT()

        await sut.loadPhotoIndex()
        await sut.search(query: "바다")

        #expect(sut.photosById.isEmpty)
        #expect(provider.getPhotos.executeCallCount == 1)
    }
}
