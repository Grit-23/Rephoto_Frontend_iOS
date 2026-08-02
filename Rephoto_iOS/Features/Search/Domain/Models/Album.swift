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
    var id: Int { tagId }
}
