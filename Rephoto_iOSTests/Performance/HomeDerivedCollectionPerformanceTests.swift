//
//  HomeDerivedCollectionPerformanceTests.swift
//  Rephoto_iOSTests
//
//  Created by 김도연 on 7/23/26.
//
//  #40 관찰 성능 최적화의 근거 벤치마크 — 파생 컬렉션 전략 A/B.
//
//  A. 계산 프로퍼티(#47 이전): body 평가마다 전체 배열 filter 재실행
//  B. didSet 캐싱(현재 HomeViewModel): photos 변경 시 1회 갱신, 읽기는 저장 프로퍼티 접근
//
//  "body 평가 100회 × 사진 100/1000/10000" 시나리오로 읽기 비용을 비교하고,
//  didSet 방식이 대신 지불하는 쓰기(photos 교체) 비용도 함께 기록한다.
//

import XCTest
@testable import Rephoto_iOS

final class HomeDerivedCollectionPerformanceTests: XCTestCase {

    // MARK: - 전략 A: 계산 프로퍼티 (#47 이전 HomeViewModel 방식)

    private final class ComputedPropertyModel {
        var photos: [Photo] = []
        var visiblePhotos: [Photo] { photos.filter { !$0.isSensitive } }
        var sensitivePhotos: [Photo] { photos.filter(\.isSensitive) }
        var sensitiveCount: Int { sensitivePhotos.count }
    }

    // MARK: - 전략 B: didSet 캐싱 (현재 HomeViewModel 방식과 동일한 갱신 로직)

    private final class DidSetCacheModel {
        var photos: [Photo] = [] {
            didSet {
                visiblePhotos = photos.filter { !$0.isSensitive }
                sensitivePhotos = photos.filter(\.isSensitive)
                sensitiveCount = sensitivePhotos.count
            }
        }
        private(set) var visiblePhotos: [Photo] = []
        private(set) var sensitivePhotos: [Photo] = []
        private(set) var sensitiveCount: Int = 0
    }

    // MARK: - 헬퍼

    private func makePhotos(count: Int) -> [Photo] {
        MockDataFactory.photoResponseDTOs(count: count).map { try! $0.toDomain() }
    }

    /// HomeView body가 읽는 파생 상태 접근을 재현: 그리드(visiblePhotos) + 민감 사진 배너(sensitiveCount)
    private func simulateBodyEvaluations<T>(_ count: Int, visible: () -> [T], sensitiveCount: () -> Int) -> Int {
        var checksum = 0
        for _ in 0..<count {
            checksum += visible().count + sensitiveCount()
        }
        return checksum
    }

    // MARK: - A. 계산 프로퍼티 — body 평가 100회

    func test_computedProperty_bodyEval100_photos100() {
        let model = ComputedPropertyModel()
        model.photos = makePhotos(count: 100)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(100, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }

    func test_computedProperty_bodyEval100_photos1000() {
        let model = ComputedPropertyModel()
        model.photos = makePhotos(count: 1000)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(100, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }

    func test_computedProperty_bodyEval100_photos10000() {
        let model = ComputedPropertyModel()
        model.photos = makePhotos(count: 10000)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(100, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }

    // MARK: - B. didSet 캐싱 — body 평가 100회

    func test_didSetCache_bodyEval100_photos100() {
        let model = DidSetCacheModel()
        model.photos = makePhotos(count: 100)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(100, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }

    func test_didSetCache_bodyEval100_photos1000() {
        let model = DidSetCacheModel()
        model.photos = makePhotos(count: 1000)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(100, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }

    func test_didSetCache_bodyEval100_photos10000() {
        let model = DidSetCacheModel()
        model.photos = makePhotos(count: 10000)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(100, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }

    // MARK: - B의 트레이드오프: photos 교체 시 didSet 갱신 비용 (쓰기 1회)

    /// didSet 방식이 읽기 대신 지불하는 비용 — fetchPhotos()로 배열이 통째로 교체될 때 1회 발생
    func test_didSetCache_photosAssign_10000() {
        let photos = makePhotos(count: 10000)
        let model = DidSetCacheModel()
        measure(metrics: [XCTClockMetric()]) {
            model.photos = photos
            XCTAssertEqual(model.visiblePhotos.count + model.sensitivePhotos.count, 10000)
        }
    }
}
