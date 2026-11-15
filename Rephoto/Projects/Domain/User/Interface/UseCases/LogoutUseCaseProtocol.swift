//
//  LogoutUseCaseProtocol.swift
//  UserDomainInterface
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

/// @mockable
public protocol LogoutUseCaseProtocol: Sendable {
    func execute() async throws
}
