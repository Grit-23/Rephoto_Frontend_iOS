//
//  ThumbnailTier.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/18/26.
//

import Foundation
import CoreGraphics
import Nuke

/// 썸네일 디코드 크기 티어.
///
/// Nuke는 resize processor의 크기를 캐시 키(`identifier`)에 포함하므로, 같은 URL을 다른 크기로
/// 요청하면 캐시 엔트리가 별개로 쌓인다. 크기를 여기 두 개로 못박아 파편화의 상한을 잡는다.
///
/// 단위는 포인트 — Nuke가 `Screen.scale`을 곱해 픽셀로 환산한다.
/// 또한 `upscale`은 기본 false라 원본이 티어보다 작으면 프로세서가 키우지 않는다.
enum ThumbnailTier {
    /// 3열 정사각 그리드 타일 — 홈·민감 사진·검색 결과·앨범 상세.
    /// iPhone 세로 기준 실제 타일 폭은 약 130pt이므로 여유가 있다
    case grid

    /// 2열 앨범 카드 커버(약 170×150pt)와 앨범 상세 배너 스트립 공용.
    /// 배너는 사진이 1~2장뿐인 앨범에서만 스트립이 이보다 넓어져 흐려지는데,
    /// 스크림과 타이틀이 덮는 배경이라 카드와 캐시를 공유하는 이득이 더 크다고 보고 감수한다
    case card

    var size: CGSize {
        switch self {
        case .grid: CGSize(width: 150, height: 150)
        case .card: CGSize(width: 200, height: 160)
        }
    }

    /// 이 티어 크기로 다운샘플하는 이미지 요청
    func request(_ url: URL) -> ImageRequest {
        ImageRequest(
            url: url,
            processors: [.resize(size: size, contentMode: .aspectFill)]
        )
    }
}
