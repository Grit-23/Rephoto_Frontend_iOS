//
//  AppContainer.swift
//  Rephoto
//
//  Created by Doyeon Kim on 11/6/26.
//

import Foundation
import Factory
import AlbumDomain
import AlbumDomainInterface
import DesignSystem
import HomeFeature
import HomeFeatureInterface
import NetworkAdapter
import PhotoDomain
import PhotoDomainInterface
import PreviewSupport
import RephotoFoundation
import SearchFeature
import TagDomain
import TagDomainInterface

/// 구현 모듈을 조립하는 유일한 지점. Feature는 여기서 만든 객체를 init으로 받는다.
///
/// DEBUG 빌드는 Repository만 PreviewSupport의 메모리 구현으로 바꿔 서버 · 로그인 없이 띄운다.
/// UseCase · Provider는 그대로라 Example 앱에서 본 동작이 App에서도 같다.
/// 실행 인자로 서버 · Stub을 고르는 전환은 로그인이 붙을 때 넣는다.
///
/// Factory 클로저는 nonisolated에서 돌므로 MainActor 타입(`ErrorHandler` · Provider · `PhotoDetailBuilder`)은
/// 메인 스레드 해석을 전제로 `assumeIsolated`로 만든다. 해석은 SwiftUI 루트 뷰 초기화에서만 일어난다.
nonisolated extension Container {

    // MARK: - Network

    private var networkClient: Factory<NetworkClient> {
        self { AuthSystemFactory.makeNetworkClient(baseURL: URL(string: Config.baseURL)!) }
            .singleton
    }

    private var adapter: Factory<NetworkAdapter> {
        self { NetworkAdapter(networkClient: self.networkClient(), baseURL: URL(string: Config.baseURL)!) }
            .singleton
    }

    // MARK: - Repositories

    private var photoRepository: Factory<any PhotoRepositoryProtocol> {
        self { PhotoRepository(adapter: self.adapter()) }
            .onDebug { _ in PreviewPhotoRepository() }
            .singleton
    }

    private var tagRepository: Factory<any TagRepositoryProtocol> {
        self { TagRepository(adapter: self.adapter()) }
            .onDebug { _ in PreviewTagRepository() }
            .singleton
    }

    private var descriptionRepository: Factory<any DescriptionRepositoryProtocol> {
        self { DescriptionRepository(adapter: self.adapter()) }
            .onDebug { _ in PreviewDescriptionRepository() }
            .singleton
    }

    // Preview 앨범 · 검색은 Home과 같은 `photoRepository`(Preview)를 읽어 삭제 · 업로드가 바로 반영된다.
    private var albumRepository: Factory<any AlbumRepositoryProtocol> {
        self { AlbumRepository(adapter: self.adapter()) }
            .onDebug { _ in PreviewAlbumRepository(photoRepository: self.photoRepository()) }
            .singleton
    }

    private var searchRepository: Factory<any SearchRepositoryProtocol> {
        self { SearchRepository(adapter: self.adapter()) }
            .onDebug { _ in PreviewSearchRepository(photoRepository: self.photoRepository()) }
            .singleton
    }

    // MARK: - Services

    private var photoMetadataExtractor: Factory<any PhotoMetadataExtractorProtocol> {
        self { PhotoMetadataExtractor() }
    }

    // MARK: - Feature

    var homeUseCaseProvider: Factory<any HomeUseCaseProviderProtocol> {
        self {
            MainActor.assumeIsolated {
                HomeUseCaseProvider(
                    photoRepository: self.photoRepository(),
                    tagRepository: self.tagRepository(),
                    descriptionRepository: self.descriptionRepository(),
                    metadataExtractor: self.photoMetadataExtractor()
                )
            }
        }
    }

    /// 앨범 사진 · 색인은 Home과 같은 `photoRepository` 싱글턴을 쓴다.
    var searchUseCaseProvider: Factory<any SearchUseCaseProviderProtocol> {
        self {
            MainActor.assumeIsolated {
                SearchUseCaseProvider(
                    albumRepository: self.albumRepository(),
                    photoRepository: self.photoRepository(),
                    searchRepository: self.searchRepository()
                )
            }
        }
    }

    /// Search가 사진 상세를 열 때 쓰는 Home의 공장. Home 화면과 같은 Provider · `ErrorHandler`로 만든다.
    var photoDetailBuilder: Factory<any PhotoDetailBuilding> {
        self {
            MainActor.assumeIsolated {
                PhotoDetailBuilder(provider: self.homeUseCaseProvider(), errorHandler: self.errorHandler())
            }
        }
    }

    // MARK: - Error

    /// 전역 에러 Alert의 단일 수집 지점. 세션 만료 훅은 User 이관 때 여기서 주입한다.
    var errorHandler: Factory<ErrorHandler> {
        self { MainActor.assumeIsolated { ErrorHandler() } }
            .singleton
    }
}
