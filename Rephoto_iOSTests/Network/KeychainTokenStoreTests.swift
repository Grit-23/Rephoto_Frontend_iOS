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
//     deinit에서 정리해 다른 테스트/실행과 격리한다.
//

import Foundation
import Testing
@testable import Rephoto_iOS

@Suite("KeychainTokenStore")
final class KeychainTokenStoreTests {

    private let sut: KeychainTokenStore

    init() {
        sut = KeychainTokenStore(service: "com.rephoto.tests.\(UUID().uuidString)")
    }

    deinit {
        let store = sut
        Task { try? await store.clear() }
    }

    @Test("저장한 토큰이 그대로 조회된다")
    func saveThenGetReturnsStoredTokens() async throws {
        try await sut.save(accessToken: "access-1", refreshToken: "refresh-1")

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == "access-1")
        #expect(refresh == "refresh-1")
    }

    @Test("저장된 것이 없으면 nil을 반환한다")
    func getWhenEmptyReturnsNil() async {
        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == nil)
        #expect(refresh == nil)
    }

    @Test("같은 키에 다시 저장하면 이전 값을 덮어쓴다")
    func saveTwiceOverwritesPreviousValue() async throws {
        try await sut.save(accessToken: "old", refreshToken: "old-r")
        try await sut.save(accessToken: "new", refreshToken: "new-r")

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == "new")
        #expect(refresh == "new-r")
    }

    @Test("clear는 저장된 토큰을 모두 삭제한다")
    func clearRemovesAllTokens() async throws {
        try await sut.save(accessToken: "a", refreshToken: "r")

        try await sut.clear()

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == nil)
        #expect(refresh == nil)
    }

    @Test("서로 다른 service의 저장소는 토큰을 공유하지 않는다")
    func differentServicesAreIsolated() async throws {
        let other = KeychainTokenStore(service: "com.rephoto.tests.other.\(UUID().uuidString)")
        defer { Task { try? await other.clear() } }

        try await sut.save(accessToken: "mine", refreshToken: "r")

        let otherAccess = await other.getAccessToken()
        #expect(otherAccess == nil, "다른 service에선 보이지 않아야 한다")
    }

    @Test("동시 다발 저장/조회가 actor로 직렬화되어 크래시 없이 일관된 상태로 끝난다")
    func concurrentAccessIsSerializedWithoutCrash() async throws {
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<100 {
                group.addTask { [sut] in
                    if index % 2 == 0 {
                        try? await sut.save(accessToken: "a-\(index)", refreshToken: "r-\(index)")
                    } else {
                        _ = await sut.getAccessToken()
                    }
                }
            }
        }

        // 마지막에 명시적으로 저장한 값이 조회된다(직렬화 보장).
        try await sut.save(accessToken: "final", refreshToken: "final-r")
        let access = await sut.getAccessToken()
        #expect(access == "final")
    }
}
