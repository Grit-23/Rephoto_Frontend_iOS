//
//  TokenPerformanceTests.swift
//  Rephoto_iOSTests
//
//  Token 관리 성능 벤치마크
//  리팩토링 항목 #2: Keychain + Actor 기반 토큰 관리
//

import XCTest
@testable import Rephoto_iOS

final class TokenPerformanceTests: XCTestCase {

    private var store: KeychainTokenStore!

    override func setUp() {
        super.setUp()
        store = KeychainTokenStore(service: "com.rephoto.tests")
    }

    override func tearDown() async throws {
        try? await store.clear()
        try await super.tearDown()
    }

    // MARK: - Keychain 토큰 쓰기 성능

    /// 토큰 저장 1000회 (Keychain)
    func test_tokenStore_save_1000() async throws {
        measure(metrics: [XCTClockMetric()]) {
            let exp = expectation(description: "save")
            Task {
                for i in 0..<1000 {
                    try await self.store.save(
                        accessToken: "access-token-\(i)",
                        refreshToken: "refresh-token-\(i)"
                    )
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 30)
        }
    }

    // MARK: - Keychain 토큰 읽기 성능

    /// 토큰 읽기 1000회
    func test_tokenStore_read_1000() async throws {
        try await store.save(accessToken: "test-access", refreshToken: "test-refresh")

        measure(metrics: [XCTClockMetric()]) {
            let exp = expectation(description: "read")
            Task {
                for _ in 0..<1000 {
                    _ = await self.store.getAccessToken()
                    _ = await self.store.getRefreshToken()
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 30)
        }
    }

    /// hasTokens 체크 1000회 (매 API 호출마다 발생)
    func test_tokenStore_hasTokens_check_1000() async throws {
        try await store.save(accessToken: "a", refreshToken: "r")

        measure(metrics: [XCTClockMetric()]) {
            let exp = expectation(description: "hasTokens")
            Task {
                for _ in 0..<1000 {
                    _ = await self.store.getAccessToken() != nil
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 30)
        }
    }

    // MARK: - 토큰 갱신 시나리오 (저장→읽기→덮어쓰기 사이클)

    /// 실제 리프레시 플로우 시뮬레이션: 읽기 → 만료 확인 → 새 토큰 저장
    func test_tokenRefreshCycle_500() async throws {
        try await store.save(accessToken: "initial-access", refreshToken: "initial-refresh")

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let exp = expectation(description: "refresh")
            Task {
                for i in 0..<500 {
                    _ = await self.store.getAccessToken()
                    _ = await self.store.getRefreshToken()
                    _ = await self.store.getAccessToken() != nil
                    try await self.store.save(
                        accessToken: "refreshed-access-\(i)",
                        refreshToken: "refreshed-refresh-\(i)"
                    )
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 60)
        }
    }

    // MARK: - clear 성능

    /// 토큰 삭제 1000회 (로그아웃 시나리오)
    func test_tokenStore_clear_1000() {
        measure(metrics: [XCTClockMetric()]) {
            let exp = expectation(description: "clear")
            Task {
                for i in 0..<1000 {
                    try await self.store.save(accessToken: "a-\(i)", refreshToken: "r-\(i)")
                    try await self.store.clear()
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 30)
        }
    }
}
