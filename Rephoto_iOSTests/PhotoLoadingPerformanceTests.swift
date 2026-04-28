//
//  PhotoLoadingPerformanceTests.swift
//  Rephoto_iOSTests
//
//  사진 로딩 및 파일 I/O 성능 벤치마크
//  리팩토링 항목 #4: 현재 Data(contentsOf:) 동기 로딩 + 순차 처리
//

import XCTest
import UIKit
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
            for _ in 0..<100 {
                UIColor(red: .random(in: 0...1), green: .random(in: 0...1),
                        blue: .random(in: 0...1), alpha: 0.5).setFill()
                ctx.fill(CGRect(x: Int.random(in: 0..<width), y: Int.random(in: 0..<height),
                                width: Int.random(in: 10...100), height: Int.random(in: 10...100)))
            }
        }
        let data = image.jpegData(compressionQuality: quality)!
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("perf_\(UUID().uuidString).jpg")
        try! data.write(to: url)
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
                try? FileManager.default.copyItem(at: source, to: dest)
                try? FileManager.default.removeItem(at: dest)
            }
        }
    }

    // MARK: - 현재 방식: 로딩 + EXIF 파싱 파이프라인

    /// 파일 읽기 → EXIF 파싱 10장 순차 (현재 전체 플로우)
    func test_loadAndParseEXIF_10photos() {
        let urls = (0..<10).map { _ in makeTempJPEG(width: 4000, height: 3000) }

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
