//
//  SearchResponseDTO.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/16/25.
//

import Foundation

struct SearchResponseDTO: Codable {
    let query: String
    let searchResults: [SearchResultDTO]
}
