//
//  AddTagUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

protocol AddTagUseCaseProtocol {
    func execute(photoId: Int, tagName: String) async throws -> PhotoTag
}
