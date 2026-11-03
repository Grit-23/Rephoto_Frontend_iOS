//
//  GetTagsUseCaseProtocol.swift
//  TagDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

/// @mockable
public protocol GetTagsUseCaseProtocol: Sendable {
    func execute(photoId: Int) async throws -> [PhotoTag]
}
