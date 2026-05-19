//
//  UserRepositoryProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation

protocol UserRepositoryProtocol {
    func login(loginId: String, password: String) async throws
    func fetchUser() async throws -> UserInfo
    func logout() async throws
    var hasTokens: Bool { get }
    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void)
}
