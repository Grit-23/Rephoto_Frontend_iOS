//
//  DeleteTagUseCaseProtocol.swift
//  TagDomainInterface
//
//  Created by 김도연 on 7/17/26.
//

import Foundation

/// @mockable
public protocol DeleteTagUseCaseProtocol: Sendable {
    func execute(photoTagId: Int) async throws
}
