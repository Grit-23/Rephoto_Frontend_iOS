//
//  Loadable.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

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
enum Loadable<T: Equatable>: Equatable {

    /// 아직 로딩을 시작하지 않음
    case idle

    /// 로딩 중
    case loading

    /// 로딩 성공
    case loaded(T)

    /// 로딩 실패
    case failed(AppError)

    // MARK: - Accessors

    /// `.loaded`일 때의 값
    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    /// `.failed`일 때의 에러
    var error: AppError? {
        if case .failed(let error) = self { return error }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    /// 성공이든 실패든 한 번은 끝났는지
    var isComplete: Bool {
        switch self {
        case .loaded, .failed:
            return true
        case .idle, .loading:
            return false
        }
    }

    // MARK: - Mapping

    /// 상태는 유지하고 값만 변환한다.
    func map<U: Equatable>(_ transform: (T) -> U) -> Loadable<U> {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .loaded(let value):
            return .loaded(transform(value))
        case .failed(let error):
            return .failed(error)
        }
    }
}

// MARK: - Collection Convenience

extension Loadable where T: Collection {
    /// 로딩에 성공했지만 결과가 비어 있는 상태.
    ///
    /// `.failed`와 명확히 구분되므로 "결과 없음" 문구를 안전하게 띄울 수 있다.
    var isLoadedEmpty: Bool {
        guard case .loaded(let value) = self else { return false }
        return value.isEmpty
    }
}
