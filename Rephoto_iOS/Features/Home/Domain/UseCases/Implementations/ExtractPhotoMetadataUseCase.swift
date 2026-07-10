//
//  ExtractPhotoMetadataUseCase.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 7/10/26.
//

import Foundation

final class ExtractPhotoMetadataUseCase: ExtractPhotoMetadataUseCaseProtocol {
    private let extractor: PhotoMetadataExtractorProtocol

    init(extractor: PhotoMetadataExtractorProtocol) {
        self.extractor = extractor
    }

    func execute(imageData: Data, identifier: String?) async -> PhotoUploadItem? {
        await extractor.extract(from: imageData, identifier: identifier)
    }
}
