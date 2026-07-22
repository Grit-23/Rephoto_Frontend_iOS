//
//  DeleteTagUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/17/26.
//

import Foundation

protocol DeleteTagUseCaseProtocol {
    func execute(photoTagId: Int) async throws
}
