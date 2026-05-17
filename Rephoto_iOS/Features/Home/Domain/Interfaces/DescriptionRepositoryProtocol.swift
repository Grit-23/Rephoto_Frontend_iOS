//
//  DescriptionRepositoryProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

protocol DescriptionRepositoryProtocol {
    func getDescription(photoId: Int) async throws -> String
}
