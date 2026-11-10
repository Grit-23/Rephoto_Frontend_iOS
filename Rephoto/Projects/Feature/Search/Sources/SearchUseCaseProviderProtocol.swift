//
//  SearchUseCaseProviderProtocol.swift
//  SearchFeature
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import AlbumDomainInterface
import PhotoDomainInterface

/// Search 화면이 쓰는 UseCase를 만드는 공장. 구현은 App(서버 Repository)과 Example(PreviewSupport)이 각각 조립한다.
public protocol SearchUseCaseProviderProtocol: Sendable {
    func makeGetAlbumsUseCase() -> any GetAlbumsUseCaseProtocol
    func makeGetAlbumPhotosUseCase() -> any GetAlbumPhotosUseCaseProtocol
    func makeSearchUseCase() -> any SearchUseCaseProtocol
    /// 검색 결과를 상세 화면용 `Photo`로 보강하는 색인에 쓴다
    func makeGetPhotosUseCase() -> any GetPhotosUseCaseProtocol
}
