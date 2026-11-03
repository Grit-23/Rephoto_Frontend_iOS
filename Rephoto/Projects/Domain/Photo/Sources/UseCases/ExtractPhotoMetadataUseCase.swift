//
//  ExtractPhotoMetadataUseCase.swift
//  PhotoDomain
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import PhotoDomainInterface

public final class ExtractPhotoMetadataUseCase: ExtractPhotoMetadataUseCaseProtocol {
    private let extractor: any PhotoMetadataExtractorProtocol

    public init(extractor: any PhotoMetadataExtractorProtocol) {
        self.extractor = extractor
    }

    public func execute(imageData: Data, identifier: String?) async -> PhotoUploadItem? {
        await extractor.extract(from: imageData, identifier: identifier)
    }
}
