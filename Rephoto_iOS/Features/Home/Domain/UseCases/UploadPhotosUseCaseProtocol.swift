//
//  UploadPhotosUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

protocol UploadPhotosUseCaseProtocol {
    func execute(items: [PhotoMetadataDTO]) async throws
}
