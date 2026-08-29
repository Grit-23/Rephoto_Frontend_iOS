import Factory
import Foundation

extension Container: @retroactive AutoRegistering {

    // MARK: - Network Infrastructure

    private var networkClient: Factory<NetworkClient> {
        self {
            let baseURL = URL(string: Config.baseURL)!
            return AuthSystemFactory.makeNetworkClient(baseURL: baseURL)
        }.singleton
    }

    private var adapter: Factory<NetworkAdapter> {
        self {
            let baseURL = URL(string: Config.baseURL)!
            return NetworkAdapter(
                networkClient: self.networkClient.resolve(),
                baseURL: baseURL
            )
        }.singleton
    }

    // MARK: - Repositories

    private var photoRepository: Factory<PhotoRepositoryProtocol> {
        self { PhotoRepository(adapter: self.adapter.resolve()) }.singleton
    }

    private var tagRepository: Factory<TagRepositoryProtocol> {
        self { TagRepository(adapter: self.adapter.resolve()) }.singleton
    }

    private var descriptionRepository: Factory<DescriptionRepositoryProtocol> {
        self { DescriptionRepository(adapter: self.adapter.resolve()) }.singleton
    }

    private var searchRepository: Factory<SearchRepositoryProtocol> {
        self { SearchRepository(adapter: self.adapter.resolve()) }.singleton
    }

    private var albumRepository: Factory<AlbumRepositoryProtocol> {
        self { AlbumRepository(adapter: self.adapter.resolve()) }.singleton
    }

    private var userRepository: Factory<UserRepositoryProtocol> {
        self {
            UserRepository(
                adapter: self.adapter.resolve(),
                networkClient: self.networkClient.resolve()
            )
        }.singleton
    }

    // MARK: - Services

    private var photoMetadataExtractor: Factory<PhotoMetadataExtractorProtocol> {
        self { PhotoMetadataExtractor() }
    }

    // MARK: - UseCaseProviders

    var homeUseCaseProvider: Factory<HomeUseCaseProviderProtocol> {
        self {
            HomeUseCaseProvider(
                photoRepository: self.photoRepository.resolve(),
                tagRepository: self.tagRepository.resolve(),
                descriptionRepository: self.descriptionRepository.resolve(),
                metadataExtractor: self.photoMetadataExtractor.resolve()
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

    // MARK: - Error

    /// 전역 에러 Alert의 단일 수집 지점. @MainActor 타입이라 메인 스레드 해석을 전제로 한다.
    ///
    /// 세션 만료 훅은 `SessionStore`(Feature 계층)를 Core가 참조하지 않도록
    /// 여기 조립 시점에 주입한다.
    var errorHandler: Factory<ErrorHandler> {
        self {
            MainActor.assumeIsolated {
                let handler = ErrorHandler()
                // sessionStore를 즉시 resolve하면 두 싱글턴이 서로를 생성하며 순환하므로,
                // 훅이 실제로 불릴 때 해석하도록 미룬다
                handler.onSessionExpired = {
                    Container.shared.sessionStore().forceLogout()
                }
                return handler
            }
        }.singleton
    }

    // MARK: - Session

    /// 앱 전역 세션. @MainActor 타입이므로 메인 스레드 해석을 전제로 한다 (SwiftUI 뷰 초기화 시점).
    var sessionStore: Factory<SessionStore> {
        self {
            MainActor.assumeIsolated {
                SessionStore(provider: self.userUseCaseProvider.resolve())
            }
        }.singleton
    }

    // MARK: - AutoRegistering

    public func autoRegister() {
        #if DEBUG
        homeUseCaseProvider.register { MockHomeUseCaseProvider() }
        searchUseCaseProvider.register { MockSearchUseCaseProvider() }
        userUseCaseProvider.register { MockUserUseCaseProvider() }
        #endif
    }
}
