//
//  Album.swift
//  AlbumDomainInterface
//
//  Created by 김도연 on 5/18/26.
//

import Foundation

// Hashable — NavigationLink(value:) / navigationDestination(for:)의 값 기반 라우팅에 쓰인다
public struct Album: Identifiable, Hashable, Sendable {
    public let tagId: Int
    public let tagName: String
    /// 앨범 카드 대표 사진 — 사진이 없는 앨범은 nil
    public let coverImageUrl: URL?
    public let photoCount: Int
    public var id: Int { tagId }

    public init(tagId: Int, tagName: String, coverImageUrl: URL?, photoCount: Int) {
        self.tagId = tagId
        self.tagName = tagName
        self.coverImageUrl = coverImageUrl
        self.photoCount = photoCount
    }
}
