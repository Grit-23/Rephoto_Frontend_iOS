//
//  SearchRepositoryProtocol.swift
//  PhotoDomainInterface
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

/// @mockable
public protocol SearchRepositoryProtocol: Sendable {
    func search(query: String) async throws -> [SearchResult]
}
