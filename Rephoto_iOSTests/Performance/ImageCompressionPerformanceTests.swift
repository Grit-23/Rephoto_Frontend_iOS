//
//  ImageCompressionPerformanceTests.swift
//  Rephoto_iOSTests
//
//  이미지 압축 성능 벤치마크
//  현재 레거시: 압축 없이 원본 JPEG(quality 1.0) 그대로 S3 업로드
//

import XCTest
import UIKit
@testable import Rephoto_iOS

final class ImageCompressionPerformanceTests: XCTestCase {

    // MARK: - 테스트용 이미지 생성

    private func makeTestImage(width: Int, height: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { ctx in
            let colors = [UIColor.blue.cgColor, UIColor.red.cgColor, UIColor.green.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors as CFArray,
                                      locations: [0, 0.5, 1])!
            ctx.cgContext.drawLinearGradient(gradient,
                                            start: .zero,
                                            end: CGPoint(x: width, y: height),
                                            options: [])
            for i in 0..<200 {
                let rect = CGRect(
                    x: (i * 37) % width,
                    y: (i * 53) % height,
                    width: 5 + ((i * 7) % 46),
                    height: 5 + ((i * 11) % 46)
                )
                UIColor(
                    red: CGFloat((i * 17) % 255) / 255.0,
                    green: CGFloat((i * 29) % 255) / 255.0,
                    blue: CGFloat((i * 43) % 255) / 255.0,
                    alpha: 0.5
                ).setFill()
                ctx.fill(rect)
            }
        }
    }

    // MARK: - 현재 방식: 원본 그대로 업로드

    /// 현재 코드: Data를 그대로 업로드 (4000x3000, iPhone 사진 크기)
    func test_noCompression_originalData_4K() {
        let image = makeTestImage(width: 4000, height: 3000)
        let originalData = image.jpegData(compressionQuality: 1.0)!

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let uploadData = originalData
            XCTAssertGreaterThan(uploadData.count, 0)
        }
    }

    /// 현재 코드: JPEG quality 1.0으로 변환하는 비용
    func test_jpegCompression_quality100_4K() {
        let image = makeTestImage(width: 4000, height: 3000)
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let data = image.jpegData(compressionQuality: 1.0)!
            _ = data.count
        }
    }
}
