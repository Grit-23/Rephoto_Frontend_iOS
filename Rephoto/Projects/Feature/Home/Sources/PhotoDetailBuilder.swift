//
//  PhotoDetailBuilder.swift
//  HomeFeature
//
//  Created by Doyeon Kim on 11/10/26.
//

import SwiftUI
import DesignSystem
import HomeFeatureInterface
import PhotoDomainInterface

public struct PhotoDetailBuilder: PhotoDetailBuilding {
    private let provider: any HomeUseCaseProviderProtocol
    private let errorHandler: ErrorHandler

    public init(provider: any HomeUseCaseProviderProtocol, errorHandler: ErrorHandler) {
        self.provider = provider
        self.errorHandler = errorHandler
    }

    public func makePhotoDetail(photo: Photo) -> AnyView {
        AnyView(PhotoInfoView(photo: photo, provider: provider, errorHandler: errorHandler))
    }
}
