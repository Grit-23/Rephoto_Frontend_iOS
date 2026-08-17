//
//  PhotoNavGrid.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/17/26.
//

import SwiftUI

/// 사진 3열 그리드 공용 컴포넌트 — 타일 탭 시 값 기반 push(NavigationLink)와
/// 사진 상세로의 줌 전환(matchedTransitionSource)까지 포함
/// 좌우 여백 없이(edge-to-edge) 배치하는 것이 기본 — 사진 앱과 같은 밀도
struct PhotoNavGrid: View {
    let photos: [Photo]
    let namespace: Namespace.ID
    var spacing: CGFloat = 2

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3),
            spacing: spacing
        ) {
            ForEach(photos) { photo in
                NavigationLink(value: photo) {
                    PhotoGridTile(imageUrl: photo.imageUrl)
                        .matchedTransitionSource(id: photo.photoId, in: namespace)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
