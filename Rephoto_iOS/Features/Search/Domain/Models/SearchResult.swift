//
//  SearchResult.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/18/26.
//

import Foundation

struct SearchResult: Identifiable, Sendable {
    let imageUrl: URL
    let photoId: Int
    var id: Int { photoId }
}
