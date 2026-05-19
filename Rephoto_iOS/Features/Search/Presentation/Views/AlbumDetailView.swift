//
//  AlbumDetailView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import SwiftUI
import NukeUI

struct AlbumDetailView: View {
    let album: Album
    @State private var albumVM: AlbumViewModel

    init(album: Album, provider: SearchUseCaseProviderProtocol) {
        self.album = album
        self._albumVM = State(initialValue: AlbumViewModel(provider: provider))
    }

    var body: some View {
        ScrollView {
            if albumVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                photoGrid
            }
        }
        .navigationTitle(album.tagName)
        .task { await albumVM.fetchAlbumPhotos(tagId: album.tagId) }
    }

    private var photoGrid: some View {
        GeometryReader { geo in
            let side: CGFloat = geo.size.width / 2 - 16
            let cols = Array(repeating: GridItem(.fixed(side), spacing: 8), count: 2)

            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(albumVM.albumPhotos, id: \.photoId) { photo in
                    LazyImage(url: photo.imageUrl) { state in
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
            .padding(8)
        }
    }
}

#if DEBUG
#Preview("Album Detail") {
    NavigationStack {
        AlbumDetailView(
            album: Album(tagId: 1, tagName: "바다"),
            provider: MockSearchUseCaseProvider()
        )
    }
}
#endif
