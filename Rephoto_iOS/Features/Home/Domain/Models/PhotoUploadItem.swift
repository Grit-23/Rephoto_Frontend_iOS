//
//  PhotoUploadItem.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

struct PhotoUploadItem: Sendable {
    let latitude: Double
    let longitude: Double
    let imageUrl: String
    let createdAt: String
    let fileName: String
}
