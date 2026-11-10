//
//  PhotoDetailBuilding.swift
//  HomeFeatureInterface
//
//  Created by Doyeon Kim on 11/10/26.
//

import SwiftUI
import PhotoDomainInterface

/// 다른 Feature가 Home의 사진 상세 화면을 열 때 쓰는 공장. 구현은 HomeFeature, 조립은 App이 맡는다.
///
/// 반환 타입이 `AnyView`인 건 상세 화면 타입을 Interface 밖으로 드러내지 않기 위해서다.
public protocol PhotoDetailBuilding: Sendable {
    func makePhotoDetail(photo: Photo) -> AnyView
}
