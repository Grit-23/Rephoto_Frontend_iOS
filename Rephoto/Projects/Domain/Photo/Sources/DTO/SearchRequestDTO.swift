//
//  SearchRequestDTO.swift
//  PhotoDomain
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation

struct SearchRequestDTO: Encodable, Sendable {
    let query: String
}
