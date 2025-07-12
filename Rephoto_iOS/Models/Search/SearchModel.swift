//
//  SearchModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/10/25.
//

import SwiftUI

struct CategoryItem: Identifiable, Decodable {
    let id: Int
    let tag: String
    let imageUrl: URL
}
