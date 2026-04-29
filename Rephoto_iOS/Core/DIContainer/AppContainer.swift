//
//  AppContainer.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 4/29/26.
//

import Factory
import Moya

extension Container: @retroactive AutoRegistering {

    // MARK: - Token

    private var tokenStore: Factory<TokenStore> {
        self { TokenStore.shared }.singleton
    }

    // MARK: - Auth

    private var authPlugin: Factory<AuthPlugin> {
        self {
            let store = self.tokenStore.resolve()
            return AuthPlugin(tokenStore: store)
        }
    }

    var authedProvider: Factory<AuthedProvider> {
        self {
            let store = self.tokenStore.resolve()
            return AuthedProvider(tokenStore: store)
        }.singleton
    }

    // MARK: - Providers

    var photosProvider: Factory<MoyaProvider<PhotosAPITarget>> {
        self {
            MoyaProvider<PhotosAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    var searchProvider: Factory<MoyaProvider<SearchAPITarget>> {
        self {
            MoyaProvider<SearchAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    var albumProvider: Factory<MoyaProvider<AlbumAPITarget>> {
        self {
            MoyaProvider<AlbumAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    var tagProvider: Factory<MoyaProvider<TagAPITarget>> {
        self {
            MoyaProvider<TagAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    var descriptionProvider: Factory<MoyaProvider<DescriptionAPITarget>> {
        self {
            MoyaProvider<DescriptionAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    /// 인증 불필요한 요청용 (로그인 등)
    var plainUserProvider: Factory<MoyaProvider<UserAPITarget>> {
        self { MoyaProvider<UserAPITarget>() }.singleton
    }

    // MARK: - AutoRegistering

    public func autoRegister() {
        authedProvider.register {
            let store = self.tokenStore.resolve()
            return AuthedProvider(tokenStore: store)
        }
    }
}
