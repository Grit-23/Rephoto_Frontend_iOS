//
//  LoadableTests.swift
//  RephotoFoundationTests
//
//  Created by Doyeon Kim on 11/2/26.
//

import Testing
@testable import RephotoFoundation

/// 빈 성공 결과와 실패를 구분하고, Observation이 사용하는 상태 비교를 검증한다.
@Suite("Loadable")
struct LoadableTests {

    @Test("빈 성공 결과는 미로딩 · 로딩 중 · 실패와 다른 상태다")
    func emptyResultIsDistinctFromOtherStates() {
        let empty: Loadable<[Int]> = .loaded([])

        #expect(empty != .idle)
        #expect(empty != .loading)
        #expect(empty != .failed(.network(.timeout)))
    }

    @Test("같은 상태의 재대입과 값 · 에러가 달라진 상태를 구분한다")
    func equalityIncludesLoadedValueAndFailure() {
        let loaded: Loadable<[Int]> = .loaded([1, 2])
        let failed: Loadable<[Int]> = .failed(.network(.timeout))

        #expect(loaded == .loaded([1, 2]))
        #expect(loaded != .loaded([1]))
        #expect(failed == .failed(.network(.timeout)))
        #expect(failed != .failed(.network(.noNetwork)))
    }
}
