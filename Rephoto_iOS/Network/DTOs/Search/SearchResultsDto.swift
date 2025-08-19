//
//  SearchResults.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/16/25.
//

import Foundation

public struct SearchResults: Codable, Identifiable {
    public var imageUrl: URL
    public var photoId: Int
    public var id: Int { photoId }
}
