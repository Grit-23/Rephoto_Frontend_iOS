//
//  GetDescriptionUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

protocol GetDescriptionUseCaseProtocol {
    func execute(photoId: Int) async throws -> String
}
