//
//  ExtractPhotoMetadataUseCaseProtocol.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 7/10/26.
//

import Foundation

protocol ExtractPhotoMetadataUseCaseProtocol {
    func execute(imageData: Data, identifier: String?) async -> PhotoUploadItem?
}
