//
//  Album.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/18/26.
//

import Foundation

// Hashable — NavigationLink(value:) / navigationDestination(for:)의 값 기반 라우팅에 쓰인다
struct Album: Identifiable, Hashable, Sendable {
    let tagId: Int
    let tagName: String
    /// 앨범 카드 대표 사진 — 사진이 없는 앨범은 nil
    let coverImageUrl: URL?
    let photoCount: Int
    var id: Int { tagId }
}
