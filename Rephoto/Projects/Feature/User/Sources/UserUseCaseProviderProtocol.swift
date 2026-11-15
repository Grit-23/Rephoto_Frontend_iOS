//
//  UserUseCaseProviderProtocol.swift
//  UserFeature
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import UserDomainInterface

public protocol UserUseCaseProviderProtocol: Sendable {
    func makeLoginUseCase() -> any LoginUseCaseProtocol
    func makeFetchUserUseCase() -> any FetchUserUseCaseProtocol
    func makeLogoutUseCase() -> any LogoutUseCaseProtocol
    func hasTokens() async -> Bool
    func setOnRefreshFailed(_ handler: @escaping @Sendable () -> Void) async
}
