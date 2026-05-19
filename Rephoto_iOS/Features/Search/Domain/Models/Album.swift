//
//  Album.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/18/26.
//

import Foundation

struct Album: Identifiable, Sendable {
    let tagId: Int
    let tagName: String
    var id: Int { tagId }
}
