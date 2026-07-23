//
//  UploadMemoryBenchmark.swift
//  Rephoto_iOSTests
//
//  Created by 김도연 on 7/23/26.
//
//  업로드 전처리 메모리 피크 비교: 레거시(풀사이즈 디코드 + 재인코딩) vs 현재(ImageIO 다운샘플 2048px, #34)
//  측정 결과는 BASELINE_RESULTS.md에 기록.
//
//  측정 방식: XCTMemoryMetric의 "Memory Peak Physical"은 프로세스 전체의 단조증가 피크라
//  셋업 메모리에 오염된다. 대신 task_vm_info.phys_footprint를 폴링해
//  작업 구간의 피크 증가분(delta)을 직접 잰다. 결과는 콘솔의 🧪 라인으로 출력.
//
//  입력: 리포 루트 MockImagesReal/ 안의 가장 큰 원본 사진.
//  이 폴더는 개인 사진(GPS EXIF 포함)이라 커밋하지 않는다 — 폴더가 없으면 테스트는 자동 스킵.
//  앱/테스트 타겟 밖에 두는 이유: Resources/ 안에 넣으면 MockImages와 파일명이 겹쳐
//  번들 복사 충돌(Multiple commands produce)이 나고, 번들링 자체가 불필요하기 때문.
//  재측정하려면 카메라 원본(무보정 JPEG/HEIC)을 해당 경로에 넣고 시뮬레이터에서 개별 실행.
//

import XCTest
import UIKit
import ImageIO
@testable import Rephoto_iOS

final class UploadMemoryBenchmark: XCTestCase {

    // MARK: - 입력 픽스처

    // 시뮬레이터 테스트는 호스트 파일시스템을 그대로 읽을 수 있으므로 #filePath 기준 상대 경로 사용
    private static let originalsDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Performance/
        .deletingLastPathComponent()  // Rephoto_iOSTests/
        .deletingLastPathComponent()  // repo root
        .appendingPathComponent("MockImagesReal")

    /// 원본 폴더에서 가장 큰 사진을 고른다 (원본 = EXIF/해상도 보존본)
    private static func fixtureURL() throws -> URL {
        let fm = FileManager.default
        let exts = ["jpg", "jpeg", "heic", "png"]
        let candidates = (try? fm.contentsOfDirectory(at: originalsDir, includingPropertiesForKeys: [.fileSizeKey]))?
            .filter { exts.contains($0.pathExtension.lowercased()) } ?? []
        func size(_ url: URL) -> Int {
            (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        guard let best = candidates.max(by: { size($0) < size($1) }), size(best) > 0 else {
            throw XCTSkip("Resources/MockImagesReal/에 사진이 없습니다")
        }
        return best
    }

    private static func describe(_ url: URL, _ data: Data) -> String {
        var dims = "?x?"
        if let src = CGImageSourceCreateWithData(data as CFData, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any],
           let w = props[kCGImagePropertyPixelWidth as String] as? Int,
           let h = props[kCGImagePropertyPixelHeight as String] as? Int {
            dims = "\(w)x\(h)"
        }
        return "\(url.lastPathComponent) \(dims) \(data.count / 1024)KB"
    }

    // MARK: - phys_footprint 샘플러

    private final class FootprintSampler: @unchecked Sendable {
        private let lock = NSLock()
        private var peak: UInt64 = 0
        private var running = true

        nonisolated init() {}

        nonisolated static func current() -> UInt64 {
            var info = task_vm_info_data_t()
            var count = mach_msg_type_number_t(
                MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
            let kr = withUnsafeMutablePointer(to: &info) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
            }
            return kr == KERN_SUCCESS ? UInt64(info.phys_footprint) : 0
        }

        /// 폴링 시작. baseline을 반환한다.
        nonisolated func start() -> UInt64 {
            let baseline = Self.current()
            peak = baseline
            let thread = Thread { [self] in
                while true {
                    lock.lock()
                    guard running else { lock.unlock(); return }
                    let f = Self.current()
                    if f > peak { peak = f }
                    lock.unlock()
                    usleep(200) // 0.2ms 간격 샘플링
                }
            }
            thread.qualityOfService = .userInteractive
            thread.start()
            return baseline
        }

        nonisolated func stopPeak() -> UInt64 {
            lock.lock()
            running = false
            let p = peak
            lock.unlock()
            return p
        }
    }

    private func mb(_ bytes: UInt64) -> String {
        String(format: "%.1f", Double(bytes) / 1_048_576)
    }

    // MARK: - 레거시 경로: 풀사이즈 디코드 + 재인코딩

    /// 리팩토링 전 업로드 전처리: 원본 전체를 UIImage로 디코드(풀사이즈 비트맵 상주) 후 JPEG 재인코딩
    func test_legacy_fullDecodeReencode_peakDelta() throws {
        let url = try Self.fixtureURL()
        let data = try Data(contentsOf: url)
        print("🧪 [입력] \(Self.describe(url, data))")

        var lines: [String] = []
        for i in 1...5 {
            let sampler = FootprintSampler()
            let baseline = sampler.start()
            let t0 = CFAbsoluteTimeGetCurrent()
            autoreleasepool {
                let image = UIImage(data: data)!
                let out = image.jpegData(compressionQuality: 1.0)!
                XCTAssertGreaterThan(out.count, 0)
            }
            let dt = CFAbsoluteTimeGetCurrent() - t0
            let peak = sampler.stopPeak()
            lines.append("run\(i): peakDelta +\(mb(peak - baseline))MB, \(String(format: "%.3f", dt))s")
        }
        print("🧪 [legacy 풀디코드+재인코딩]\n" + lines.joined(separator: "\n"))
    }

    // MARK: - 현재 경로: ImageIO 다운샘플 (실제 프로덕션 코드)

    /// 현재 업로드 전처리: PhotoMetadataExtractor.extract — CGImageSource 썸네일 디코드(2048px) + quality 0.8
    func test_current_downsampleExtract_peakDelta() async throws {
        let url = try Self.fixtureURL()
        let data = try Data(contentsOf: url)
        print("🧪 [입력] \(Self.describe(url, data))")

        let extractor = PhotoMetadataExtractor()
        var lines: [String] = []
        for i in 1...5 {
            let sampler = FootprintSampler()
            let baseline = sampler.start()
            let t0 = CFAbsoluteTimeGetCurrent()
            let item = await extractor.extract(from: data, identifier: "benchmark")
            let dt = CFAbsoluteTimeGetCurrent() - t0
            let peak = sampler.stopPeak()
            XCTAssertNotNil(item)
            lines.append("run\(i): peakDelta +\(mb(peak - baseline))MB, \(String(format: "%.3f", dt))s")
        }
        // extract 내부 DEBUG print("📷 [압축] WxH beforeKB → afterKB (%)")가 페이로드 수치도 출력
        print("🧪 [current ImageIO 다운샘플]\n" + lines.joined(separator: "\n"))
    }
}
