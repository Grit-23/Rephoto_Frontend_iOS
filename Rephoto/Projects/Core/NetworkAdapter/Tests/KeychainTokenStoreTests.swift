//
//  KeychainTokenStoreTests.swift
//  NetworkAdapterTests
//
//  KeychainTokenStore의 동작 검증. Keychain 대신 메모리 항목 저장소를 주입한다.
//  - 저장/조회/삭제/덮어쓰기, 빈 상태 nil 반환, service 격리
//  - 두 번째 쓰기 실패 시 첫 번째 쓰기 되돌리기(롤백)
//  - 동시 접근 직렬화
//
//  호스트 앱 없는 xctest 번들은 Keychain에 접근할 수 없어(errSecMissingEntitlement)
//  SecItemStore 자체는 여기서 돌리지 않는다.
//

import Foundation
import Security
import Synchronization
import Testing
@testable import NetworkAdapter

@Suite("KeychainTokenStore")
struct KeychainTokenStoreTests {

    private func makeStore(
        service: String = "com.rephoto.tests",
        items: InMemoryKeychainItems = InMemoryKeychainItems()
    ) -> KeychainTokenStore {
        KeychainTokenStore(service: service, items: items)
    }

    @Test("저장한 토큰이 그대로 조회된다")
    func saveThenGetReturnsStoredTokens() async throws {
        let sut = makeStore()

        try await sut.save(accessToken: "access-1", refreshToken: "refresh-1")

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == "access-1")
        #expect(refresh == "refresh-1")
    }

    @Test("저장된 것이 없으면 nil을 반환한다")
    func getWhenEmptyReturnsNil() async {
        let sut = makeStore()

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == nil)
        #expect(refresh == nil)
    }

    @Test("같은 키에 다시 저장하면 이전 값을 덮어쓴다")
    func saveTwiceOverwritesPreviousValue() async throws {
        let sut = makeStore()
        try await sut.save(accessToken: "old", refreshToken: "old-r")

        try await sut.save(accessToken: "new", refreshToken: "new-r")

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == "new")
        #expect(refresh == "new-r")
    }

    @Test("clear는 저장된 토큰을 모두 삭제한다")
    func clearRemovesAllTokens() async throws {
        let sut = makeStore()
        try await sut.save(accessToken: "a", refreshToken: "r")

        try await sut.clear()

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == nil)
        #expect(refresh == nil)
    }

    @Test("서로 다른 service의 저장소는 토큰을 공유하지 않는다")
    func differentServicesAreIsolated() async throws {
        let items = InMemoryKeychainItems()
        let sut = makeStore(service: "com.rephoto.tests.a", items: items)
        let other = makeStore(service: "com.rephoto.tests.b", items: items)

        try await sut.save(accessToken: "mine", refreshToken: "r")

        let otherAccess = await other.getAccessToken()
        #expect(otherAccess == nil, "다른 service에선 보이지 않아야 한다")
    }

    @Test("refresh 쓰기가 실패하면 access를 이전 값으로 되돌린다")
    func failedRefreshWriteRestoresPreviousAccessToken() async throws {
        let items = InMemoryKeychainItems()
        let sut = makeStore(items: items)
        try await sut.save(accessToken: "old", refreshToken: "old-r")
        items.failWrites(to: "refreshToken")

        await #expect(throws: KeychainError.self) {
            try await sut.save(accessToken: "new", refreshToken: "new-r")
        }

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == "old", "첫 번째 쓰기를 되돌려 쌍이 어긋나지 않아야 한다")
        #expect(refresh == "old-r")
    }

    @Test("이전 값이 없을 때 refresh 쓰기가 실패하면 access를 지운다")
    func failedRefreshWriteWithoutPreviousValueDeletesAccessToken() async throws {
        let items = InMemoryKeychainItems()
        let sut = makeStore(items: items)
        items.failWrites(to: "refreshToken")

        await #expect(throws: KeychainError.self) {
            try await sut.save(accessToken: "new", refreshToken: "new-r")
        }

        let access = await sut.getAccessToken()
        let refresh = await sut.getRefreshToken()
        #expect(access == nil, "짝 없는 access가 남으면 안 된다")
        #expect(refresh == nil)
    }

    @Test("동시 다발 저장/조회가 actor로 직렬화되어 일관된 상태로 끝난다")
    func concurrentAccessIsSerialized() async throws {
        let sut = makeStore()

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<100 {
                group.addTask {
                    if index % 2 == 0 {
                        try? await sut.save(accessToken: "a-\(index)", refreshToken: "r-\(index)")
                    } else {
                        _ = await sut.getAccessToken()
                    }
                }
            }
        }

        // save는 access·refresh를 두 번의 쓰기로 저장한다. 직렬화가 깨지면 서로 다른 index의
        // 쓰기가 끼어들어 쌍이 어긋나므로, 마지막에 남은 두 값이 같은 index인지로 검증한다.
        let access = try #require(await sut.getAccessToken())
        let refresh = await sut.getRefreshToken()
        #expect(refresh == "r-\(access.dropFirst(2))")
    }
}

// MARK: - Test Doubles

/// 메모리에 항목을 담는 Keychain 더블. `failWrites(to:)`로 지정한 account의 쓰기는 실패시킨다.
final class InMemoryKeychainItems: KeychainItemStore {

    private struct State {
        var storage: [String: Data] = [:]
        var failingAccount: String?
    }

    private let state = Mutex(State())

    func failWrites(to account: String) {
        state.withLock { $0.failingAccount = account }
    }

    func read(service: String, account: String) -> Data? {
        state.withLock { $0.storage[key(service, account)] }
    }

    func write(_ data: Data, service: String, account: String) throws {
        try state.withLock { state in
            guard state.failingAccount != account else {
                throw KeychainError.saveFailed(status: errSecIO)
            }
            state.storage[key(service, account)] = data
        }
    }

    func delete(service: String, account: String) {
        state.withLock { _ = $0.storage.removeValue(forKey: key(service, account)) }
    }

    private func key(_ service: String, _ account: String) -> String {
        "\(service)/\(account)"
    }
}
