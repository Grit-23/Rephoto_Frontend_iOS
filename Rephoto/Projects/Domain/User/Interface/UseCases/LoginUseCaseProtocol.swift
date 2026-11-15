//
//  LoginUseCaseProtocol.swift
//  UserDomainInterface
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

/// @mockable
public protocol LoginUseCaseProtocol: Sendable {
    func execute(loginId: String, password: String) async throws
}
