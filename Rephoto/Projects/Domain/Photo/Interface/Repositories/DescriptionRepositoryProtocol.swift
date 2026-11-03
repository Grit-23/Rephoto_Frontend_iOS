//
//  DescriptionRepositoryProtocol.swift
//  PhotoDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

/// @mockable
public protocol DescriptionRepositoryProtocol: Sendable {
    func getDescription(photoId: Int) async throws -> String
}
