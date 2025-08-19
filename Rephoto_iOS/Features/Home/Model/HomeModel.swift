//
//  HomeModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/12/25.
//

import Foundation
import CoreLocation

struct HomeModel: Codable, Identifiable {
    var id = UUID()
    var photoId: Int
    var imageUrl: URL
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var fileName: String
    var tags: [String]
    var isSensitive: Bool
}
