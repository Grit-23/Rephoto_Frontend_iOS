//
//  SearchResult.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/18/26.
//

import Foundation

struct SearchResult: Identifiable {
    let imageUrl: URL
    let photoId: Int
    var id: Int { photoId }
}
