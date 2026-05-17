//
//  UpdateTagUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

protocol UpdateTagUseCaseProtocol {
    func execute(photoTagId: Int, tagName: String) async throws -> PhotoTag
}
