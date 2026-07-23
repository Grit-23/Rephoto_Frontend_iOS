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
    /// 검색 결과(photoId)를 상세 화면용 전체 Photo로 매핑하기 위한 홈 사진 색인
    @State private var photosById: [Int: Photo] = [:]
    @Namespace private var photoZoom
    @Injected(\.homeUseCaseProvider) private var homeProvider

    init(provider: SearchUseCaseProviderProtocol) {
        self._searchVM = State(initialValue: SearchViewModel(provider: provider))
        self._albumVM = State(initialValue: AlbumViewModel(provider: provider))
    }

    var body: some View {
        NavigationStack {
            ScrollView { content }
                .background(Color.base.ignoresSafeArea())
                .navigationTitle("검색")
                .toolbarTitleDisplayMode(.inlineLarge)
                .searchable(text: $searchVM.query, prompt: "사진을 검색해보세요!")
                .onSubmit(of: .search) {
                    Task { await searchVM.search(query: searchVM.query) }
                }
                .onChange(of: searchVM.query) { _, newValue in
                    if newValue.isEmpty {
                        searchVM.searchResults = []
                    }
                }
                .navigationDestination(for: Photo.self) { photo in
                    PhotoInfoView(photo: photo, provider: homeProvider)
                        // 홈과 동일하게 타일에서 사진이 확대되어 나오는 줌 전환
                        .navigationTransition(.zoom(sourceID: photo.photoId, in: photoZoom))
                }
        }
        .task {
            await albumVM.fetchAlbums()
            if let photos = try? await homeProvider.makeGetPhotosUseCase().execute() {
                photosById = Dictionary(uniqueKeysWithValues: photos.map { ($0.photoId, $0) })
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if searchVM.isLoading {
            ProgressView("검색 중…")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if searchVM.query.isEmpty {
            if albumVM.isLoading {
                ProgressView("앨범 불러오는 중…")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if albumVM.albums.isEmpty {
                SearchEmptyStateView(
                    title: "아직 앨범이 없어요",
                    subtitle: "같은 태그를 가진 사진을 추가해보세요"
                )
            } else {
                AlbumGridSection(
                    albums: albumVM.albums,
                    previews: albumVM.albumPreviews,
                    provider: albumVM.provider,
                    namespace: photoZoom
                )
            }
        } else if searchVM.searchResults.isEmpty {
            SearchEmptyStateView(
                title: "‘\(searchVM.query)’에 대한 결과가 없어요",
                subtitle: "다른 검색어나 태그로 다시 찾아보세요"
            )
        } else {
            SearchResultGrid(
                query: searchVM.query,
                results: searchVM.searchResults,
                namespace: photoZoom,
                photoResolver: photo(for:)
            )
        }
    }

    /// 홈 사진 색인에서 전체 메타데이터를 찾고, 없으면 검색 결과 정보만으로 구성
    private func photo(for result: SearchResult) -> Photo {
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

// MARK: - AlbumGridSection

/// "앨범 n개" 헤더 + 2열 앨범 카드 그리드
private struct AlbumGridSection: View {
    let albums: [Album]
    let previews: [Int: AlbumViewModel.AlbumPreview]
    let provider: SearchUseCaseProviderProtocol
    let namespace: Namespace.ID

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
                    NavigationLink {
                        AlbumDetailView(album: album, provider: provider, namespace: namespace)
                    } label: {
                        AlbumCard(album: album, preview: previews[album.tagId])
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
    let preview: AlbumViewModel.AlbumPreview?

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
                if let preview {
                    Text("\(preview.photoCount)장")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.85))
                }
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
        if let thumbnailUrl = preview?.thumbnailUrl {
            Color.clear
                .overlay {
                    LazyImage(url: thumbnailUrl) { state in
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
    let namespace: Namespace.ID
    let photoResolver: (SearchResult) -> Photo

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("‘\(query)’ 검색 결과 · 사진 \(results.count)장")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.labelSecondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(results) { item in
                    NavigationLink(value: photoResolver(item)) {
                        SearchResultTile(imageUrl: item.imageUrl)
                            .matchedTransitionSource(id: item.photoId, in: namespace)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - SearchResultTile

/// 검색 결과 정사각 썸네일 타일
private struct SearchResultTile: View {
    let imageUrl: URL

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                LazyImage(url: imageUrl) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
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
