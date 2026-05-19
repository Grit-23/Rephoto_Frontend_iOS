//
//  FetchUserUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

protocol FetchUserUseCaseProtocol {
    func execute() async throws -> UserInfo
}
