//
//  SearchUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

protocol SearchUseCaseProtocol {
    func execute(query: String) async throws -> [SearchResult]
}
