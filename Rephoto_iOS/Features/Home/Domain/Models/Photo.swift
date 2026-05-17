//
//  Photo.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

struct Photo: Identifiable, Hashable, Sendable {
    var id: Int { photoId }
    let photoId: Int
    let imageUrl: URL
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    let fileName: String
    let tags: [String]
    let isSensitive: Bool
}
