//
//  DateFormatterPerformanceTests.swift
//  Rephoto_iOSTests
//
//  DateFormatter 성능 벤치마크
//  현재 코드: toHomeModel()에서 매번 DateFormatter를 새로 생성
//

import XCTest
@testable import Rephoto_iOS

final class DateFormatterPerformanceTests: XCTestCase {

    /// 현재 방식: 매번 DateFormatter를 새로 생성 (toHomeModel 내부 로직)
    func test_dateFormatter_createEveryTime_1000() {
        let dateStrings = (1...1000).map {
            "2025-07-\(String(format: "%02d", ($0 % 28) + 1))T12:00:00"
        }
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for str in dateStrings {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                _ = formatter.date(from: str)
            }
        }
    }
}
