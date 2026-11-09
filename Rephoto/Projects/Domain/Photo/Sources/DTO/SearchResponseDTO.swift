//
//  SearchResponseDTO.swift
//  PhotoDomain
//
//  Created by 김도연 on 8/16/25.
//

import Foundation

struct SearchResponseDTO: Decodable {
    let query: String
    let searchResults: [SearchResultDTO]
}
