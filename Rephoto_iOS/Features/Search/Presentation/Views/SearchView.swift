//
//  SearchView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import NukeUI

struct SearchView: View {
    @State private var searchVM: SearchViewModel
    @State private var albumVM: AlbumViewModel

    init(provider: SearchUseCaseProviderProtocol) {
        self._searchVM = State(initialValue: SearchViewModel(provider: provider))
        self._albumVM = State(initialValue: AlbumViewModel(provider: provider))
    }

    var body: some View {
        NavigationStack {
            ScrollView { content }
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
        }
        .task { await albumVM.fetchAlbums() }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if searchVM.isLoading {
            ProgressView("검색 중…")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if searchVM.query.isEmpty {
            if albumVM.albums.isEmpty {
                Text("\n앨범이 없습니다. \n같은 태그를 가진 사진을 추가해보세요!")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .bold()
            } else {
                albumGrid
            }
        } else if searchVM.searchResults.isEmpty {
            Text("검색 결과가 없습니다.")
                .padding()
        } else {
            searchResultGrid
        }
    }

    // MARK: - Album Grid

    private var albumGrid: some View {
        GeometryReader { geo in
            let side: CGFloat = geo.size.width / 2 - 16
            let cols = Array(repeating: GridItem(.fixed(side), spacing: 8), count: 2)

            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(albumVM.albums) { album in
                    NavigationLink {
                        AlbumDetailView(album: album, provider: albumVM.provider)
                    } label: {
                        albumCell(side: side, title: album.tagName)
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Search Result Grid

    private var searchResultGrid: some View {
        GeometryReader { geo in
            let side: CGFloat = geo.size.width / 2 - 16
            let cols = Array(repeating: GridItem(.fixed(side), spacing: 8), count: 2)

            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(searchVM.searchResults) { item in
                    resultTile(side: side, url: item.imageUrl)
                }
            }
            .padding(8)
        }
    }

    // MARK: - Components

    private func albumCell(side: CGFloat, title: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            Color.gray
                .frame(width: side, height: side)
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .padding(8)
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func resultTile(side: CGFloat, url: URL) -> some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: side, height: side)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Color.gray
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#if DEBUG
#Preview("Search") {
    SearchView(provider: MockSearchUseCaseProvider())
}
#endif
