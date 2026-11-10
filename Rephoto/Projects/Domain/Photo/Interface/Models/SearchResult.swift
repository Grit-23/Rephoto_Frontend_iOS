//
//  SearchResult.swift
//  PhotoDomainInterface
//
//  Created by 김도연 on 5/18/26.
//

import Foundation

// Equatable은 Loadable<[SearchResult]> 상태 비교에 필요하다
public struct SearchResult: Identifiable, Sendable, Equatable {
    public let imageUrl: URL
    public let photoId: Int
    public var id: Int { photoId }

    public init(imageUrl: URL, photoId: Int) {
        self.imageUrl = imageUrl
        self.photoId = photoId
    }
}
