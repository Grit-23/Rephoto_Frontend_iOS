//
//  FetchUserUseCaseProtocol.swift
//  UserDomainInterface
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

/// @mockable
public protocol FetchUserUseCaseProtocol: Sendable {
    func execute() async throws -> UserInfo
}
