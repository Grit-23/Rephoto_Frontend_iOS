//
//  SearchRepositoryProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

protocol SearchRepositoryProtocol {
    func search(query: String) async throws -> [SearchResult]
}
