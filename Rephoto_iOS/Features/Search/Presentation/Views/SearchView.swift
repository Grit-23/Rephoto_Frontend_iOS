//
//  SearchView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import NukeUI
import Factory

struct SearchView: View {
    @State private var searchVM: SearchViewModel
    @State private var albumVM: AlbumViewModel
    @Namespace private var photoZoom
    @Injected(\.homeUseCaseProvider) private var homeProvider

    init(provider: SearchUseCaseProviderProtocol) {
        self._searchVM = State(initialValue: SearchViewModel(
            provider: provider,
            getPhotosUseCase: Container.shared.homeUseCaseProvider().makeGetPhotosUseCase()
        ))
        self._albumVM = State(initialValue: AlbumViewModel(provider: provider))
    }

    var body: some View {
        NavigationStack {
            ScrollView { content }
                .background(Color.base.ignoresSafeArea())
                .navigationTitle("검색")
                .toolbarTitleDisplayMode(.inlineLarge)
                .searchable(text: $searchVM.query, prompt: "사진을 검색해보세요!")
                // task(id:)는 검색어가 바뀔 때마다 이전 작업을 자동 취소하므로,
                // 300ms 대기 중 취소 = 디바운스가 됨. 대기를 통과한 마지막 검색어만 요청된다
                .task(id: searchVM.query) {
                    guard !trimmedQuery.isEmpty else {
                        searchVM.clearResults()
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    await searchVM.search(query: trimmedQuery)
                }
                // destination은 lazy 컨테이너 밖, 스택 루트에 등록한다
                .navigationDestination(for: Album.self) { album in
                    AlbumDetailView(album: album, provider: albumVM.provider, namespace: photoZoom)
                }
                .navigationDestination(for: Photo.self) { photo in
                    PhotoInfoView(photo: photo, provider: homeProvider)
                        // 홈과 동일하게 타일에서 사진이 확대되어 나오는 줌 전환
                        .navigationTransition(.zoom(sourceID: photo.photoId, in: photoZoom))
                }
        }
        .task {
            await albumVM.fetchAlbums()
            await searchVM.loadPhotoIndex()
        }
    }

    // MARK: - Content

    /// 공백만 입력한 검색어를 빈 검색어로 취급 — 분기·요청·표시가 같은 기준을 쓴다
    private var trimmedQuery: String {
        searchVM.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 검색어가 비어 있으면 앨범 목록, 아니면 검색 결과를 보여준다.
    /// 두 경로 모두 `.failed`를 `.loaded([])`와 분리해 다루므로,
    /// 네트워크 실패가 "없어요"로 둔갑하지 않는다.
    @ViewBuilder
    private var content: some View {
        if trimmedQuery.isEmpty {
            albumContent
        } else {
            searchContent
        }
    }

    @ViewBuilder
    private var albumContent: some View {
        switch albumVM.albums {
        case .idle, .loading:
            ProgressView("앨범 불러오는 중…")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        case .failed(let error):
            ErrorStateView(error: error) {
                await albumVM.fetchAlbums()
            }
            .padding(.top, 80)
        case .loaded(let albums) where albums.isEmpty:
            SearchEmptyStateView(
                title: "아직 앨범이 없어요",
                subtitle: "같은 태그를 가진 사진을 추가해보세요"
            )
        case .loaded(let albums):
            AlbumGridSection(albums: albums)
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        switch searchVM.searchResults {
        case .idle, .loading:
            ProgressView("검색 중…")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        case .failed(let error):
            ErrorStateView(error: error) {
                await searchVM.search(query: trimmedQuery)
            }
            .padding(.top, 80)
        case .loaded(let results) where results.isEmpty:
            SearchEmptyStateView(
                title: "‘\(trimmedQuery)’에 대한 결과가 없어요",
                subtitle: "다른 검색어나 태그로 다시 찾아보세요"
            )
        case .loaded(let results):
            SearchResultGrid(
                query: trimmedQuery,
                results: results,
                photosById: searchVM.photosById,
                namespace: photoZoom
            )
        }
    }
}

// MARK: - AlbumGridSection

/// "앨범 n개" 헤더 + 2열 앨범 카드 그리드
private struct AlbumGridSection: View {
    let albums: [Album]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("앨범")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                Text("\(albums.count)개")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.labelTertiary)
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(albums) { album in
                    // 값 기반 링크로 통일 — 뷰를 직접 넘기는 링크와 섞으면, 앨범 안에서
                    // 사진(value)을 push할 때 SwiftUI가 앨범(view)을 pop했다가 다시 덮는다
                    NavigationLink(value: album) {
                        AlbumCard(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - AlbumCard

/// 앨범 카드 — 대표 사진 배경 + 하단 스크림 위 앨범명/장수
private struct AlbumCard: View {
    let album: Album

    /// 대표 썸네일이 없을 때 태그별로 고정되는 배경 그라데이션 팔레트
    private static let gradients: [(Color, Color)] = [
        (Color(red: 0x7F / 255, green: 0xA6 / 255, blue: 0xAD / 255), Color(red: 0x4C / 255, green: 0x6E / 255, blue: 0x75 / 255)),
        (Color(red: 0x8B / 255, green: 0xAE / 255, blue: 0x73 / 255), Color(red: 0x5A / 255, green: 0x7C / 255, blue: 0x45 / 255)),
        (Color(red: 0x96 / 255, green: 0xA2 / 255, blue: 0xAE / 255), Color(red: 0x61 / 255, green: 0x6E / 255, blue: 0x7C / 255)),
        (Color(red: 0xC3 / 255, green: 0x9F / 255, blue: 0x7C / 255), Color(red: 0x96 / 255, green: 0x6F / 255, blue: 0x52 / 255)),
        (Color(red: 0xD0 / 255, green: 0xA5 / 255, blue: 0x7E / 255), Color(red: 0xA8 / 255, green: 0x7A / 255, blue: 0x54 / 255)),
        (Color(red: 0x6E / 255, green: 0x7A / 255, blue: 0x93 / 255), Color(red: 0x45 / 255, green: 0x4E / 255, blue: 0x66 / 255)),
    ]

    private var gradient: (Color, Color) {
        Self.gradients[abs(album.tagId) % Self.gradients.count]
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            background

            LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                .frame(height: 80)
                .frame(maxHeight: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 2) {
                Text(album.tagName)
                    .font(.system(size: 20, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                Text("\(album.photoCount)장")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.leading, 16)
            .padding(.bottom, 12)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(red: 0x29 / 255, green: 0x33 / 255, blue: 0x29 / 255).opacity(0.12), radius: 7, y: 6)
    }

    @ViewBuilder
    private var background: some View {
        if let coverImageUrl = album.coverImageUrl {
            Color.clear
                .overlay {
                    // 2열 카드 크기만큼만 디코드 (170×150pt에 여유분)
                    LazyImage(request: ThumbnailTier.card.request(coverImageUrl)) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(colors: [gradient.0, gradient.1], startPoint: .top, endPoint: .bottom)
                        }
                    }
                }
        } else {
            LinearGradient(colors: [gradient.0, gradient.1], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - SearchResultGrid

/// "'검색어' 검색 결과 · 사진 n장" 헤더 + 3열 결과 타일 그리드
private struct SearchResultGrid: View {
    let query: String
    let results: [SearchResult]
    let photosById: [Int: Photo]
    let namespace: Namespace.ID

    var body: some View {
        // 그리드는 홈과 동일하게 화면 끝까지(edge-to-edge), 헤더만 여백 유지
        VStack(alignment: .leading, spacing: 14) {
            Text("‘\(query)’ 검색 결과 · 사진 \(results.count)장")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.labelSecondary)
                .padding(.horizontal, 20)

            PhotoNavGrid(items: resolvedPhotos, imageUrl: \.imageUrl, namespace: namespace)
        }
        .padding(.top, 8)
    }

    /// 홈 사진 색인에서 전체 메타데이터를 찾고, 없으면 검색 결과 정보만으로 구성.
    /// photoId를 identity로 쓰므로 SearchResult 기반 ForEach와 행 identity가 동일하다
    private var resolvedPhotos: [Photo] {
        results.map { result in
            photosById[result.photoId] ?? Photo(
                photoId: result.photoId,
                imageUrl: result.imageUrl,
                latitude: 0,
                longitude: 0,
                createdAt: Date(),
                fileName: "",
                tags: [],
                isSensitive: false
            )
        }
    }
}

// MARK: - SearchEmptyStateView

/// 앨범 없음/검색 결과 없음 공용 빈 상태 뷰
private struct SearchEmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.mainGreen)
                .frame(width: 96, height: 96)
                .background(.subGreen, in: Circle())

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.labelSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 41)
        .padding(.top, 160)
    }
}

#if DEBUG
#Preview("Search") {
    SearchView(provider: MockSearchUseCaseProvider())
}
#endif
