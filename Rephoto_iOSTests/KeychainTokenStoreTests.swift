//
//  KeychainTokenStoreTests.swift
//  Rephoto_iOSTests
//
//  Keychain 기반 actor TokenStore의 동작 검증.
//  - 저장/조회/삭제/덮어쓰기
//  - 빈 상태 nil 반환
//  - 동시 접근 직렬화(크래시 없음)
//
//  ⚠️ Keychain은 시뮬레이터에서 영속되므로, 테스트마다 고유 service를 쓰고
//     tearDown에서 정리해 다른 테스트/실행과 격리한다.
//

import XCTest
@testable import Rephoto_iOS

final class KeychainTokenStoreTests: XCTestCase {

    private var service: String = ""
    private var sut: KeychainTokenStore!

    override func setUp() async throws {
        try await super.setUp()
        service = "com.rephoto.tests.\(UUID().uuidString)"
        sut = KeychainTokenStore(service: service)
    }

    override func tearDown() async throws {
        try? await sut.clear()
        sut = nil
        try await super.tearDown()
    }

    /// 저장한 토큰이 그대로 조회된다.
    func test_save_thenGet_returnsStoredTokens() async throws {
        try await sut.save(accessToken: "access-1", refreshToken: "refresh-1")

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        XCTAssertEqual(access, "access-1")
        XCTAssertEqual(refresh, "refresh-1")
    }

    /// 저장된 것이 없으면 nil을 반환한다.
    func test_get_whenEmpty_returnsNil() async {
        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        XCTAssertNil(access)
        XCTAssertNil(refresh)
    }

    /// 같은 키에 다시 저장하면 이전 값을 덮어쓴다.
    func test_save_twice_overwritesPreviousValue() async throws {
        try await sut.save(accessToken: "old", refreshToken: "old-r")
        try await sut.save(accessToken: "new", refreshToken: "new-r")

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        XCTAssertEqual(access, "new")
        XCTAssertEqual(refresh, "new-r")
    }

    /// clear는 저장된 토큰을 모두 삭제한다.
    func test_clear_removesAllTokens() async throws {
        try await sut.save(accessToken: "a", refreshToken: "r")

        try await sut.clear()

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        XCTAssertNil(access)
        XCTAssertNil(refresh)
    }

    /// 서로 다른 service의 저장소는 토큰을 공유하지 않는다(격리).
    func test_differentServices_areIsolated() async throws {
        let other = KeychainTokenStore(service: "com.rephoto.tests.other.\(UUID().uuidString)")
        defer { Task { try? await other.clear() } }

        try await sut.save(accessToken: "mine", refreshToken: "r")

        let otherAccess = await other.getAccessToken()
        XCTAssertNil(otherAccess, "다른 service에선 보이지 않아야 한다")
    }

    /// 동시 다발 저장/조회가 actor로 직렬화되어 크래시 없이 일관된 상태로 끝난다.
    func test_concurrentAccess_isSerializedWithoutCrash() async throws {
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<100 {
                group.addTask { [sut] in
                    if index % 2 == 0 {
                        try? await sut?.save(accessToken: "a-\(index)", refreshToken: "r-\(index)")
                    } else {
                        _ = await sut?.getAccessToken()
                    }
                }
            }
        }

        // 마지막에 명시적으로 저장한 값이 조회된다(직렬화 보장).
        try await sut.save(accessToken: "final", refreshToken: "final-r")
        let access = await sut.getAccessToken()
        XCTAssertEqual(access, "final")
    }
}
