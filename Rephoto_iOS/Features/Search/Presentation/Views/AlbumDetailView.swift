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
    let namespace: Namespace.ID
    @State private var albumVM: AlbumViewModel

    init(album: Album, provider: SearchUseCaseProviderProtocol, namespace: Namespace.ID) {
        self.album = album
        self.namespace = namespace
        self._albumVM = State(initialValue: AlbumViewModel(provider: provider))
    }

    var body: some View {
        ScrollView {
            if albumVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let errorMessage = albumVM.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    AlbumBanner(title: album.tagName, photos: albumVM.albumPhotos)

                    Text("사진")
                        .font(.system(size: 20, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(.labelPrimary)
                        .padding(.leading, 4)

                    AlbumPhotoGrid(photos: albumVM.albumPhotos, namespace: namespace)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .background(Color.base.ignoresSafeArea())
        .navigationTitle(album.tagName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await albumVM.fetchAlbumPhotos(tagId: album.tagId) }
    }
}

// MARK: - AlbumBanner

/// 앨범 대표 사진 콜라주 + 스크림 위에 앨범명과 요약을 얹은 배너
private struct AlbumBanner: View {
    let title: String
    let photos: [Photo]

    private var latestDate: Date? {
        photos.map(\.createdAt).max()
    }

    var body: some View {
        ZStack(alignment: .leading) {
            BannerCollage(photos: Array(photos.prefix(3)))

            LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.45)], startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 8) {
                Text("앨범")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.28), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))

                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(.white)

                Text(summaryText)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(.leading, 22)
        }
        .frame(height: 138)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .deepGreen.opacity(0.28), radius: 12, y: 12)
    }

    private var summaryText: String {
        if let latestDate {
            return "사진 \(photos.count)장 · 최근 \(latestDate.formatted(.dateTime.month().day()))"
        }
        return "사진 \(photos.count)장"
    }
}

// MARK: - BannerCollage

/// 배너 배경 — 앨범 사진 최대 3장을 가로로 이어 붙인 콜라주
private struct BannerCollage: View {
    let photos: [Photo]

    var body: some View {
        HStack(spacing: 0) {
            if photos.isEmpty {
                LinearGradient(
                    colors: [.lightGreen, .mainGreen],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                ForEach(photos) { photo in
                    LazyImage(url: photo.imageUrl) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.gray.opacity(0.2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 138)
                    .clipped()
                }
            }
        }
    }
}

// MARK: - AlbumPhotoGrid

/// 앨범 사진 3열 그리드 — 타일 탭 시 사진 상세로 줌 전환
private struct AlbumPhotoGrid: View {
    let photos: [Photo]
    let namespace: Namespace.ID

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(photos) { photo in
                NavigationLink(value: photo) {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            LazyImage(url: photo.imageUrl) { state in
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
                        .matchedTransitionSource(id: photo.photoId, in: namespace)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#if DEBUG
#Preview("Album Detail") {
    @Previewable @Namespace var namespace
    NavigationStack {
        AlbumDetailView(
            album: Album(tagId: 1, tagName: "커피"),
            provider: MockSearchUseCaseProvider(),
            namespace: namespace
        )
    }
}
#endif
