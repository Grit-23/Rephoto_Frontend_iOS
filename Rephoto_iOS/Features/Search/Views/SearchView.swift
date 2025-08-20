//
//  SearchView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import NukeUI
import Observation

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @State private var albumVM = AlbumViewModel()

    var body: some View {
        NavigationStack {
            ScrollView { content }
                .navigationTitle("검색")
                .toolbarTitleDisplayMode(.inlineLarge)
                .searchable(text: $vm.query, prompt: "사진을 검색해보세요!")
        }
        .task { albumVM.fetchAlbums() }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            ProgressView("검색 중…")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if vm.query.isEmpty {
            if albumVM.albums.isEmpty {
                Text("\n앨범이 없습니다. \n같은 태그를 가진 사진을 추가해보세요!")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .bold()
            } else {
                albumView
            }
        } else if vm.searchResults.isEmpty {
            Text("검색 결과가 없습니다.")
                .padding()
        } else {
            results
        }
    }

    // MARK: - 앨범 리스트 & 상세
    private var albumView: some View {
        GeometryReader { geo in
            let side: CGFloat = geo.size.width / 2 - 16
            let cols: [GridItem] = Array(repeating: GridItem(.fixed(side), spacing: 8), count: 2)

            LazyVGrid(columns: cols, spacing: 8) {
                // 인덱스와 함께 순회 (앨범별 사진 배열을 인덱스로 대응)
                ForEach(Array(albumVM.albums.enumerated()), id: \.element.id) { idx, album in
                    // 이 앨범의 첫 번째 사진 URL (없으면 nil)
                    let thumbURL = (idx < albumVM.albumInfo.count) ? albumVM.albumInfo[idx].first?.imageUrl.absoluteString : nil

                    NavigationLink {
                        // 앨범 상세: 해당 앨범 인덱스의 사진만 보여줌
                        ScrollView {
                            LazyVGrid(columns: cols, spacing: 8) {
                                let photos = (idx < albumVM.albumInfo.count) ? albumVM.albumInfo[idx] : []
                                ForEach(photos, id: \.photoId) { p in
                                    photoTile(side: side, photo: p)
                                }
                            }
                            .padding(8)
                        }
                    } label: {
                        // ⬇️ 썸네일을 배경으로 쓰는 앨범 카드
                        albumCell(side: side, title: album.tagName, thumbURLString: thumbURL)
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - 검색 결과
    private var results: some View {
        GeometryReader { geo in
            let side: CGFloat = geo.size.width / 2 - 16
            let cols: [GridItem] = Array(repeating: GridItem(.fixed(side), spacing: 8), count: 2)

            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(vm.searchResults) { item in
                    resultTile(side: side, url: item.imageUrl)
                }
            }
            .padding(8)
        }
    }

    // MARK: - 작은 빌더들

    // 앨범 카드: 썸네일(첫 사진) + 그라데이션 + 제목
    @ViewBuilder
    private func albumCell(side: CGFloat, title: String, thumbURLString: String?) -> some View {
        ZStack(alignment: .bottomLeading) {
            albumBackground(side: side, thumbURLString: thumbURLString)
            // 텍스트 가독성용 그라데이션
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

    // 앨범 카드 배경: 썸네일 있으면 이미지, 없으면 플레이스홀더
    @ViewBuilder
    private func albumBackground(side: CGFloat, thumbURLString: String?) -> some View {
        if let s = thumbURLString, let url = URL(string: s) {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: side, height: side)
                        .clipped()
                } else {
                    placeholder(side: side)
                }
            }
        } else {
            placeholder(side: side)
        }
    }

    // 상세/검색 타일 공용
    @ViewBuilder
    private func photoTile(side: CGFloat, photo: HomeModel) -> some View {
        LazyImage(url: photo.imageUrl) { state in
            if let image = state.image {
                NavigationLink {
                    PhotoInfoView(photo: photo)
                } label: {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: side, height: side)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                placeholder(side: side)
            }
        }
    }

    @ViewBuilder
    private func resultTile(side: CGFloat, url: URL) -> some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                NavigationLink {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                } label: {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: side, height: side)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                placeholder(side: side)
            }
        }
    }

    @ViewBuilder
    private func placeholder(side: CGFloat) -> some View {
        Color.gray
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview { SearchView() }
