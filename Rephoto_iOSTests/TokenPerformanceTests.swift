//
//  TokenPerformanceTests.swift
//  Rephoto_iOSTests
//
//  Token 관리 성능 벤치마크
//  리팩토링 항목 #2: Token 관리 로직 수정
//  현재: UserDefaults에 직접 저장 → Keychain 또는 메모리 캐시로 변경 시 비교용
//

import XCTest
@testable import Rephoto_iOS

final class TokenPerformanceTests: XCTestCase {

    override func tearDown() {
        TokenStore.shared.clear()
        super.tearDown()
    }

    // MARK: - UserDefaults 토큰 쓰기 성능

    /// 토큰 저장 1000회 (현재 방식: UserDefaults)
    func test_tokenStore_save_1000() {
        let store = TokenStore.shared
        measure(metrics: [XCTClockMetric()]) {
            for i in 0..<1000 {
                store.save(TokenPair(
                    accessToken: "access-token-\(i)",
                    refreshToken: "refresh-token-\(i)"
                ))
            }
        }
    }

    // MARK: - UserDefaults 토큰 읽기 성능

    /// 토큰 읽기 1000회
    func test_tokenStore_read_1000() {
        let store = TokenStore.shared
        store.save(TokenPair(accessToken: "test-access", refreshToken: "test-refresh"))

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<1000 {
                _ = store.accessToken
                _ = store.refreshToken
            }
        }
    }

    /// hasTokens 체크 1000회 (매 API 호출마다 발생)
    func test_tokenStore_hasTokens_check_1000() {
        let store = TokenStore.shared
        store.save(TokenPair(accessToken: "a", refreshToken: "r"))

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<1000 {
                _ = store.hasTokens
            }
        }
    }

    // MARK: - 토큰 갱신 시나리오 (저장→읽기→덮어쓰기 사이클)

    /// 실제 리프레시 플로우 시뮬레이션: 읽기 → 만료 확인 → 새 토큰 저장
    func test_tokenRefreshCycle_500() {
        let store = TokenStore.shared
        store.save(TokenPair(accessToken: "initial-access", refreshToken: "initial-refresh"))

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for i in 0..<500 {
                // 1. 현재 토큰 읽기
                let _ = store.accessToken
                let _ = store.refreshToken
                // 2. hasTokens 확인
                let _ = store.hasTokens
                // 3. 새 토큰 저장 (리프레시 성공 시)
                store.save(TokenPair(
                    accessToken: "refreshed-access-\(i)",
                    refreshToken: "refreshed-refresh-\(i)"
                ))
            }
        }
    }

    // MARK: - clear 성능

    /// 토큰 삭제 1000회 (로그아웃 시나리오)
    func test_tokenStore_clear_1000() {
        let store = TokenStore.shared

        measure(metrics: [XCTClockMetric()]) {
            for i in 0..<1000 {
                store.save(TokenPair(accessToken: "a-\(i)", refreshToken: "r-\(i)"))
                store.clear()
            }
        }
    }
}
