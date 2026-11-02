//
//  PhotoGridTile.swift
//  DesignSystem
//
//  Created by 김도연 on 7/17/26.
//

import SwiftUI
import NukeUI

/// 사진 그리드 공용 정사각 썸네일 타일 — 홈/민감/검색 결과/앨범 상세에서 사용
public struct PhotoGridTile: View {
    private let imageUrl: URL

    public init(imageUrl: URL) {
        self.imageUrl = imageUrl
    }

    public var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                LazyImage(request: ThumbnailTier.grid.request(imageUrl)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
