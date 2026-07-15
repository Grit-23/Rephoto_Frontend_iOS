//
//  PhotoLoadingPerformanceTests.swift
//  Rephoto_iOSTests
//
//  사진 로딩 및 파일 I/O 성능 벤치마크
//  리팩토링 항목 #4: 현재 Data(contentsOf:) 동기 로딩 + 순차 처리
//

import XCTest
import UIKit
import ImageIO
@testable import Rephoto_iOS

final class PhotoLoadingPerformanceTests: XCTestCase {

    private var tempFiles: [URL] = []

    override func tearDown() {
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
        super.tearDown()
    }

    private func makeTempJPEG(width: Int, height: Int, quality: CGFloat = 0.8) -> URL {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            for i in 0..<100 {
                let rect = CGRect(
                    x: (i * 37) % width,
                    y: (i * 53) % height,
                    width: 10 + ((i * 7) % 91),
                    height: 10 + ((i * 11) % 91)
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
        let data = image.jpegData(compressionQuality: quality)!
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("perf_\(UUID().uuidString).jpg")
        try! data.write(to: url)
        tempFiles.append(url)
        return url
    }

    /// EXIF/GPS 메타데이터가 포함된 JPEG 생성
    private func makeTempJPEGWithEXIF(width: Int, height: Int) -> URL {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        let imageData = image.jpegData(compressionQuality: 0.8)!

        let source = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let uti = CGImageSourceGetType(source)!
        let mutableData = NSMutableData()
        let destination = CGImageDestinationCreateWithData(mutableData, uti, 1, nil)!

        let exifDict: [String: Any] = [
            kCGImagePropertyExifDateTimeOriginal as String: "2025:07:15 12:00:00",
            kCGImagePropertyExifLensMake as String: "TestLens",
            kCGImagePropertyExifISOSpeedRatings as String: [100],
            kCGImagePropertyExifFNumber as String: 2.8
        ]
        let gpsDict: [String: Any] = [
            kCGImagePropertyGPSLatitude as String: 37.5665,
            kCGImagePropertyGPSLatitudeRef as String: "N",
            kCGImagePropertyGPSLongitude as String: 126.9780,
            kCGImagePropertyGPSLongitudeRef as String: "E"
        ]
        let properties: [String: Any] = [
            kCGImagePropertyExifDictionary as String: exifDict,
            kCGImagePropertyGPSDictionary as String: gpsDict
        ]

        CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)
        CGImageDestinationFinalize(destination)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("perf_exif_\(UUID().uuidString).jpg")
        try! (mutableData as Data).write(to: url)
        tempFiles.append(url)
        return url
    }

    // MARK: - 현재 방식: Data(contentsOf:) 동기 로딩

    /// 4K 이미지 1장 로딩
    func test_dataContentsOf_4K() {
        let url = makeTempJPEG(width: 4000, height: 3000)

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = try! Data(contentsOf: url)
        }
    }

    // MARK: - 현재 방식: for loop 순차 로딩 (handlePickedItems)

    /// 10장 순차 로딩
    func test_sequentialLoad_10photos() {
        let urls = (0..<10).map { _ in makeTempJPEG(width: 1920, height: 1080) }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for url in urls {
                _ = try! Data(contentsOf: url)
            }
        }
    }

    // MARK: - 현재 방식: 파일 복사 (PHCaptureImageView copyItem)

    /// 파일 복사 10장
    func test_fileCopy_10photos() {
        let sources = (0..<10).map { _ in makeTempJPEG(width: 1920, height: 1080) }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for source in sources {
                let dest = FileManager.default.temporaryDirectory
                    .appendingPathComponent("copy_\(UUID().uuidString).jpg")
                do {
                    try FileManager.default.copyItem(at: source, to: dest)
                    try FileManager.default.removeItem(at: dest)
                } catch {
                    XCTFail("File copy/remove failed: \(error)")
                    break
                }
            }
        }
    }

    // MARK: - 현재 방식: 로딩 + EXIF 파싱 파이프라인

    /// 파일 읽기 → EXIF 파싱 10장 순차 (현재 전체 플로우)
    func test_loadAndParseEXIF_10photos() {
        let urls = (0..<10).map { _ in makeTempJPEGWithEXIF(width: 4000, height: 3000) }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for url in urls {
                let data = try! Data(contentsOf: url)
                guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { continue }
                let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
                _ = props?["{Exif}"] as? [String: Any]
                _ = props?[kCGImagePropertyGPSDictionary as String] as? [String: Any]
            }
        }
    }
}
