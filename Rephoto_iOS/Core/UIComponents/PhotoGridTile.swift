//
//  PhotoGridTile.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/17/26.
//

import SwiftUI
import Nuke
import NukeUI

/// 사진 그리드 공용 정사각 썸네일 타일 — 홈/민감/검색 결과/앨범 상세에서 사용
struct PhotoGridTile: View {
    let imageUrl: URL

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                // 타일에 필요한 크기(포인트)만 디코드·캐시 — 원본 풀 디코드 대비 메모리 ~30배 절약
                LazyImage(request: ImageRequest(
                    url: imageUrl,
                    processors: [.resize(size: CGSize(width: 150, height: 150), contentMode: .aspectFill)]
                )) { state in
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
