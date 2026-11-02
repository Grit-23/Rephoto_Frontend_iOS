//
//  KeychainTokenStoreTests.swift
//  NetworkAdapterTests
//
//  KeychainTokenStore의 동작 검증. Keychain 대신 메모리 항목 저장소를 주입한다.
//  - 토큰 쌍 저장/조회/삭제/덮어쓰기, 빈 상태 nil 반환, service 격리
//  - 저장·삭제 실패 시 기존 토큰 쌍 보존, 손상된 데이터 처리
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

    @Test("저장한 토큰 쌍이 그대로 조회된다")
    func saveThenLoadReturnsStoredTokens() throws {
        let sut = makeStore()
        let tokens = TokenPair(accessToken: "access-1", refreshToken: "refresh-1")

        try sut.save(tokens)

        #expect(sut.load() == tokens)
    }

    @Test("저장된 것이 없으면 nil을 반환한다")
    func loadWhenEmptyReturnsNil() {
        let sut = makeStore()

        #expect(sut.load() == nil)
    }

    @Test("다시 저장하면 토큰 쌍 전체를 덮어쓴다")
    func saveTwiceOverwritesPreviousPair() throws {
        let sut = makeStore()
        try sut.save(TokenPair(accessToken: "old", refreshToken: "old-r"))
        let tokens = TokenPair(accessToken: "new", refreshToken: "new-r")

        try sut.save(tokens)

        #expect(sut.load() == tokens)
    }

    @Test("clear는 토큰 쌍을 삭제한다")
    func clearRemovesStoredPair() throws {
        let sut = makeStore()
        try sut.save(TokenPair(accessToken: "a", refreshToken: "r"))

        try sut.clear()

        #expect(sut.load() == nil)
    }

    @Test("서로 다른 service의 저장소는 토큰 쌍을 공유하지 않는다")
    func differentServicesAreIsolated() throws {
        let items = InMemoryKeychainItems()
        let sut = makeStore(service: "com.rephoto.tests.a", items: items)
        let other = makeStore(service: "com.rephoto.tests.b", items: items)

        try sut.save(TokenPair(accessToken: "mine", refreshToken: "r"))

        #expect(other.load() == nil)
    }

    @Test("삭제 실패는 오류를 던지고 기존 토큰 쌍은 남는다")
    func clearFailurePreservesStoredPair() throws {
        let items = InMemoryKeychainItems()
        let sut = makeStore(items: items)
        let tokens = TokenPair(accessToken: "a", refreshToken: "r")
        try sut.save(tokens)
        items.failDeletes()

        #expect(throws: KeychainError.self) {
            try sut.clear()
        }

        #expect(sut.load() == tokens)
    }

    @Test("저장된 것이 없어도 clear는 성공한다")
    func clearWhenEmptySucceeds() throws {
        let sut = makeStore()

        try sut.clear()
    }

    @Test("저장 실패는 기존 토큰 쌍을 보존한다")
    func failedWritePreservesPreviousPair() throws {
        let items = InMemoryKeychainItems()
        let sut = makeStore(items: items)
        let tokens = TokenPair(accessToken: "old", refreshToken: "old-r")
        try sut.save(tokens)
        items.failWrites()

        #expect(throws: KeychainError.self) {
            try sut.save(TokenPair(accessToken: "new", refreshToken: "new-r"))
        }

        #expect(sut.load() == tokens)
    }

    @Test("첫 저장이 실패하면 토큰 쌍이 남지 않는다")
    func failedFirstWriteLeavesStoreEmpty() {
        let items = InMemoryKeychainItems()
        let sut = makeStore(items: items)
        items.failWrites()

        #expect(throws: KeychainError.self) {
            try sut.save(TokenPair(accessToken: "new", refreshToken: "new-r"))
        }

        #expect(sut.load() == nil)
    }

    @Test("토큰 쌍으로 디코딩할 수 없는 데이터는 nil을 반환한다")
    func corruptDataReturnsNil() throws {
        let items = InMemoryKeychainItems()
        let sut = makeStore(items: items)
        try items.write(Data("invalid tokens".utf8), service: "com.rephoto.tests", account: "tokens")

        #expect(sut.load() == nil)
    }
}

// MARK: - Test Doubles

/// 메모리에 항목을 담는 Keychain 더블. 저장·삭제 오류를 주입할 수 있다.
final class InMemoryKeychainItems: KeychainItemStore {

    private struct State {
        var storage: [String: Data] = [:]
        var shouldFailWrites = false
        var shouldFailDeletes = false
    }

    private let state = Mutex(State())

    func failWrites() {
        state.withLock { $0.shouldFailWrites = true }
    }

    func failDeletes() {
        state.withLock { $0.shouldFailDeletes = true }
    }

    func read(service: String, account: String) -> Data? {
        state.withLock { $0.storage[key(service, account)] }
    }

    func write(_ data: Data, service: String, account: String) throws {
        try state.withLock { state in
            guard !state.shouldFailWrites else {
                throw KeychainError.saveFailed(status: errSecIO)
            }
            state.storage[key(service, account)] = data
        }
    }

    func delete(service: String, account: String) throws {
        try state.withLock { state in
            guard !state.shouldFailDeletes else {
                throw KeychainError.deleteFailed(status: errSecIO)
            }
            _ = state.storage.removeValue(forKey: key(service, account))
        }
    }

    private func key(_ service: String, _ account: String) -> String {
        "\(service)/\(account)"
    }
}
