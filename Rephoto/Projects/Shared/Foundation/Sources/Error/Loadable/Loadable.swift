//
//  Loadable.swift
//  RephotoFoundation
//
//  Created by Doyeon Kim on 8/28/26.
//

/// 비동기 로딩 상태를 하나의 값으로 표현한다.
///
/// `isLoading: Bool` + `items: [T]` + `errorMessage: String?` 세 필드를 조합하던 방식은
/// "빈 결과"와 "불러오기 실패"가 똑같이 `items.isEmpty`로 보인다는 결함이 있다.
/// 이 타입은 두 상태를 서로 다른 case로 갈라 그 혼동을 타입 수준에서 막는다.
///
/// ## 사용
///
/// ```swift
/// // ViewModel
/// private(set) var albums: Loadable<[Album]> = .idle
///
/// func fetch() async {
///     albums = .loading
///     do {
///         albums = .loaded(try await useCase.execute())
///     } catch {
///         guard !error.isCancellation else { return }
///         albums = .failed(AppError.from(error))
///     }
/// }
///
/// // View
/// switch vm.albums {
/// case .idle, .loading: ProgressView()
/// case .loaded(let albums) where albums.isEmpty: EmptyStateView()
/// case .loaded(let albums): AlbumGrid(albums)
/// case .failed(let error): ErrorStateView(error: error) { await vm.fetch() }
/// }
/// ```
///
/// - SeeAlso: ``AppError``, ``ErrorStateView``
public enum Loadable<T: Equatable>: Equatable {

    /// 아직 로딩을 시작하지 않음
    case idle

    /// 로딩 중
    case loading

    /// 로딩 성공
    case loaded(T)

    /// 로딩 실패
    case failed(AppError)
}
