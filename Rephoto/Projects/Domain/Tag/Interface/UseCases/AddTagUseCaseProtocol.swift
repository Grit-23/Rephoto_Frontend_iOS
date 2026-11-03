//
//  AddTagUseCaseProtocol.swift
//  TagDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

/// @mockable
public protocol AddTagUseCaseProtocol: Sendable {
    func execute(photoId: Int, tagName: String) async throws -> PhotoTag
}
