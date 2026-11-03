//
//  GetPhotosUseCaseProtocol.swift
//  PhotoDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

/// @mockable
public protocol GetPhotosUseCaseProtocol: Sendable {
    func execute() async throws -> [Photo]
}
