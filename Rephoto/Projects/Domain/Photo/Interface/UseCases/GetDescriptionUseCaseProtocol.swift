//
//  GetDescriptionUseCaseProtocol.swift
//  PhotoDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

/// @mockable
public protocol GetDescriptionUseCaseProtocol: Sendable {
    func execute(photoId: Int) async throws -> String
}
