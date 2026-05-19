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

    // MARK: - Providers (internal)

    private var photosProvider: Factory<MoyaProvider<PhotosAPITarget>> {
        self {
            MoyaProvider<PhotosAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    private var searchProvider: Factory<MoyaProvider<SearchAPITarget>> {
        self {
            MoyaProvider<SearchAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    private var albumProvider: Factory<MoyaProvider<AlbumAPITarget>> {
        self {
            MoyaProvider<AlbumAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    private var tagProvider: Factory<MoyaProvider<TagAPITarget>> {
        self {
            MoyaProvider<TagAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    private var descriptionProvider: Factory<MoyaProvider<DescriptionAPITarget>> {
        self {
            MoyaProvider<DescriptionAPITarget>(plugins: [self.authPlugin.resolve()])
        }.singleton
    }

    /// 인증 불필요한 요청용 (로그인 등)
    var plainUserProvider: Factory<MoyaProvider<UserAPITarget>> {
        self { MoyaProvider<UserAPITarget>() }.singleton
    }

    // MARK: - Repositories (private)

    private var photoRepository: Factory<PhotoRepositoryProtocol> {
        self { PhotoRepository(provider: self.photosProvider.resolve()) }.singleton
    }

    private var tagRepository: Factory<TagRepositoryProtocol> {
        self { TagRepository(provider: self.tagProvider.resolve()) }.singleton
    }

    private var descriptionRepository: Factory<DescriptionRepositoryProtocol> {
        self { DescriptionRepository(provider: self.descriptionProvider.resolve()) }.singleton
    }
    
    private var searchRepository: Factory<SearchRepositoryProtocol> {
        self { SearchRepository(provider: self.searchProvider.resolve()) }.singleton
    }
    
    private var albumRepository: Factory<AlbumRepositoryProtocol> {
        self { AlbumRepository(provider: self.albumProvider.resolve()) }.singleton
    }

    private var userRepository: Factory<UserRepositoryProtocol> {
        self {
            UserRepository(
                plainProvider: self.plainUserProvider.resolve(),
                authedProvider: self.authedProvider.resolve(),
                tokenStore: self.tokenStore.resolve()
            )
        }.singleton
    }

    // MARK: - UseCaseProviders

    var homeUseCaseProvider: Factory<HomeUseCaseProviderProtocol> {
        self {
            HomeUseCaseProvider(
                photoRepository: self.photoRepository.resolve(),
                tagRepository: self.tagRepository.resolve(),
                descriptionRepository: self.descriptionRepository.resolve()
            )
        }
    }
    
    var searchUseCaseProvider: Factory<SearchUseCaseProviderProtocol> {
        self {
            SearchUseCaseProvider(
                albumRepository: self.albumRepository.resolve(),
                searchRepository: self.searchRepository.resolve()
            )
        }
    }

    var userUseCaseProvider: Factory<UserUseCaseProviderProtocol> {
        self {
            UserUseCaseProvider(userRepository: self.userRepository.resolve())
        }
    }

    // MARK: - AutoRegistering

    public func autoRegister() {
        authedProvider.register {
            let store = self.tokenStore.resolve()
            return AuthedProvider(tokenStore: store)
        }
    }
}
