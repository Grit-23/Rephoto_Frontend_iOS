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
            case .loaded(let photos):
                // 배너 카드가 이끄는 카드 컴포지션 화면이라, 그리드도 같은 16pt 여백을 따른다
                // (홈·검색 결과의 edge-to-edge 그리드와 의도적으로 다름)
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
                    // 앨범 카드 커버와 같은 티어를 써서 캐시를 공유한다 — 목록에서 이미 받아둔
                    // 비트맵을 상세 배너가 재사용한다. 사진 1~2장 앨범은 스트립이 티어보다
                    // 넓어져 흐려지지만, 스크림·타이틀이 덮는 배경이라 감수한다
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
}
