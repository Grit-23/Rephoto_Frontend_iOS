//
//  UpdateTagUseCaseProtocol.swift
//  TagDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

/// @mockable
public protocol UpdateTagUseCaseProtocol: Sendable {
    func execute(photoTagId: Int, tagName: String) async throws -> PhotoTag
}
