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

    // MARK: - 고반복(10,000회) 측정 — B의 절대값을 타이머 분해능 위로 끌어올리기 위함

    // 위 100회 테스트에서 B는 실기기 Release 기준 총합이 1~3µs로 나온다.
    // XCTClockMetric의 분해능이 1µs라 값이 양자화되고 상대표준편차가 30~50% 안팎으로 튄다.
    // "상수 시간"이라는 결론에는 지장이 없지만, 평가당 절대값을 인용하려면
    // 그 수치는 측정 정밀도를 넘어선 주장이 된다.
    //
    // 그래서 평가 횟수를 10,000회로 올려 총합을 키우려 했다(선형이면 200µs대). 실측은 약 7µs로
    // 3배 안팎만 늘었다 — Release에서 읽기가 루프 밖으로 빠진 것으로 보인다. 그래서 B의 평가당
    // 절대값은 인용하지 않고, 이 블록은 "B가 반복 수에 비례하지 않는다"는 근거로만 쓴다.
    // 100회 테스트는 원래 시나리오(body 평가 100회)를 그대로 두기 위해 유지한다.

    func test_didSetCache_bodyEval10000_photos100() {
        let model = DidSetCacheModel()
        model.photos = makePhotos(count: 100)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(10000, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }

    func test_didSetCache_bodyEval10000_photos1000() {
        let model = DidSetCacheModel()
        model.photos = makePhotos(count: 1000)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(10000, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }

    func test_didSetCache_bodyEval10000_photos10000() {
        let model = DidSetCacheModel()
        model.photos = makePhotos(count: 10000)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(10000, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }

    /// A의 동일 평가 횟수 대조군 — 같은 축에서 배율을 산출하고,
    /// 평가당 비용이 평가 횟수에 선형인지(= 100회 측정이 유효한지) 교차 검증한다.
    func test_computedProperty_bodyEval10000_photos1000() {
        let model = ComputedPropertyModel()
        model.photos = makePhotos(count: 1000)
        measure(metrics: [XCTClockMetric()]) {
            let checksum = simulateBodyEvaluations(10000, visible: { model.visiblePhotos }, sensitiveCount: { model.sensitiveCount })
            XCTAssertGreaterThan(checksum, 0)
        }
    }
}
