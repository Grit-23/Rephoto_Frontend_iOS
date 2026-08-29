//
//  SearchResult.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/18/26.
//

import Foundation

// Equatable은 Loadable<[SearchResult]> 상태 비교에 필요하다
struct SearchResult: Identifiable, Sendable, Equatable {
    let imageUrl: URL
    let photoId: Int
    var id: Int { photoId }
}
