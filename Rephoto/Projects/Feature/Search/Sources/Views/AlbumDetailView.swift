//
//  AlbumDetailView.swift
//  SearchFeature
//
//  Created by 김도연 on 5/19/26.
//

import SwiftUI
import NukeUI
import DesignSystem
import AlbumDomainInterface
import PhotoDomainInterface
import RephotoFoundation

struct AlbumDetailView: View {
    let album: Album
    let namespace: Namespace.ID
    @State private var albumVM: AlbumViewModel

    init(album: Album, provider: any SearchUseCaseProviderProtocol, namespace: Namespace.ID) {
        self.album = album
        self.namespace = namespace
        self._albumVM = State(initialValue: AlbumViewModel(provider: provider))
    }

    var body: some View {
        ScrollView {
            switch albumVM.albumPhotos {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            case .failed(let error):
                ErrorStateView(error: error) {
                    await albumVM.fetchAlbumPhotos(tagId: album.tagId)
                }
                .padding(.top, 80)
            case .loaded(let photos) where photos.isEmpty:
                SearchEmptyStateView(
                    systemImage: "photo.on.rectangle.angled",
                    title: "앨범에 사진이 없어요",
                    subtitle: "이 태그가 붙은 사진이 더 이상 없어요"
                )
            case .loaded(let photos):
                VStack(alignment: .leading, spacing: 20) {
                    AlbumBanner(title: album.tagName, photos: photos)

                    Text("사진")
                        .font(.system(size: 20, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(.labelPrimary)
                        .padding(.leading, 4)

                    PhotoNavGrid(
                        items: photos,
                        imageUrl: \.imageUrl,
                        namespace: namespace,
                        spacing: 8
                    )
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
        .shadow(color: .gray.opacity(0.3), radius: 7, y: 6)
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
            ForEach(photos) { photo in
                LazyImage(request: ThumbnailTier.card.request(photo.imageUrl)) { state in
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
