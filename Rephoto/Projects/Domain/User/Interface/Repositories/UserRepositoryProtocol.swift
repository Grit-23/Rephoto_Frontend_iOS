//
//  UserRepositoryProtocol.swift
//  UserDomainInterface
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

/// @mockable
public protocol UserRepositoryProtocol: Sendable {
    func login(loginId: String, password: String) async throws
    func fetchUser() async throws -> UserInfo
    func logout() async throws
    func hasTokens() async -> Bool
    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void)
}
