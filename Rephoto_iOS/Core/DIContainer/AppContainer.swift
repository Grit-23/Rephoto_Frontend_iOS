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

    // MARK: - AutoRegistering

    public func autoRegister() {
        authedProvider.register {
            let store = self.tokenStore.resolve()
            return AuthedProvider(tokenStore: store)
        }
    }
}
