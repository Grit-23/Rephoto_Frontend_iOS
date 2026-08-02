//
//  UploadMemoryBenchmark.swift
//  Rephoto_iOSTests
//
//  Created by 김도연 on 7/23/26.
//
//  업로드 전처리 메모리 피크 비교: 풀디코드 대조군(전체 디코드 + 재인코딩) vs 현재(ImageIO 다운샘플, #34)
//  측정 결과는 BASELINE_RESULTS.md에 기록.
//
//  라벨 정정(2026-08-02): 대조군은 리팩토링 전 앱의 재현이 아니다. 실제 레거시 앱(#34 이전)은
//  픽셀을 디코드하지 않고 EXIF만 읽은 뒤 원본 파일을 그대로 업로드했다(전처리 상주 ≈ 원본 Data).
//  이 테스트는 "다운샘플하지 않는 표준 구현"의 메모리 기준선으로 유지한다.
//
//  측정 방식: XCTMemoryMetric의 "Memory Peak Physical"은 프로세스 전체의 단조증가 피크라
//  셋업 메모리에 오염된다. 대신 task_vm_info.phys_footprint를 폴링해
//  작업 구간의 피크 증가분(delta)을 직접 잰다. 결과는 콘솔의 🧪 라인으로 출력.
//
//  입력: 카메라 원본 사진(무보정 JPEG/HEIC) 중 가장 큰 것. 두 위치를 순서대로 찾는다.
//   1. 테스트 번들의 Performance/Fixtures/ — 실기기 실행용. 기기에는 #filePath 경로가
//      존재하지 않으므로 번들 동봉이 유일한 수단이다.
//   2. 리포 루트 MockImagesReal/ — 시뮬레이터 실행용(호스트 파일시스템 직접 읽기).
//  둘 다 없으면 테스트는 자동 스킵.
//
//  두 폴더 모두 개인 사진(GPS EXIF 포함)이라 커밋하지 않는다 (.gitignore).
//  앱 타겟 Resources/ 에 넣지 말 것 — MockImages와 파일명이 겹쳐 번들 복사 충돌
//  (Multiple commands produce)이 난다. 테스트 타겟은 별개 번들이라 충돌하지 않는다.
//

import XCTest
import UIKit
import ImageIO
import UniformTypeIdentifiers
@testable import Rephoto_iOS

final class UploadMemoryBenchmark: XCTestCase {

    // MARK: - 입력 픽스처

    private static let photoExtensions = ["jpg", "jpeg", "heic", "png"]

    // 시뮬레이터 테스트는 호스트 파일시스템을 그대로 읽을 수 있으므로 #filePath 기준 상대 경로 사용
    private static let originalsDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Performance/
        .deletingLastPathComponent()  // Rephoto_iOSTests/
        .deletingLastPathComponent()  // repo root
        .appendingPathComponent("MockImagesReal")

    /// 번들 동봉본(실기기) → 호스트 폴더(시뮬레이터) 순으로 찾아 가장 큰 사진을 고른다.
    /// 가장 큰 것 = 원본(EXIF/해상도 보존본).
    /// `DecodeVariantBenchTests`가 동일 입력을 쓰기 위해 internal.
    static func fixtureURL() throws -> URL {
        if let bundled = largestPhoto(in: bundledCandidates()) { return bundled }
        if let onHost = largestPhoto(in: hostCandidates()) { return onHost }
        throw XCTSkip("""
            원본 사진 픽스처를 찾지 못했습니다.
            · 실기기: Rephoto_iOSTests/Performance/Fixtures/ 에 카메라 원본을 두세요 (테스트 번들에 동봉됨)
            · 시뮬레이터: 리포 루트 MockImagesReal/ 도 가능
            """)
    }

    /// 테스트 번들에 동봉된 픽스처. 동기화 그룹이 리소스를 번들 루트로 평탄화하는 경우와
    /// Fixtures/ 하위를 유지하는 경우 둘 다 훑는다.
    private static func bundledCandidates() -> [URL] {
        let bundle = Bundle(for: UploadMemoryBenchmark.self)
        let subdirectories: [String?] = [nil, "Fixtures"]
        return subdirectories
            .flatMap { bundle.urls(forResourcesWithExtension: nil, subdirectory: $0) ?? [] }
            .filter { photoExtensions.contains($0.pathExtension.lowercased()) }
    }

    private static func hostCandidates() -> [URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: originalsDir,
            includingPropertiesForKeys: [.fileSizeKey]
        )) ?? []
        return urls.filter { photoExtensions.contains($0.pathExtension.lowercased()) }
    }

    private static func largestPhoto(in candidates: [URL]) -> URL? {
        func size(_ url: URL) -> Int {
            (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        guard let best = candidates.max(by: { size($0) < size($1) }), size(best) > 0 else {
            return nil
        }
        return best
    }

    static func describe(_ url: URL, _ data: Data) -> String {
        var dims = "?x?"
        if let src = CGImageSourceCreateWithData(data as CFData, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any],
           let w = props[kCGImagePropertyPixelWidth as String] as? Int,
           let h = props[kCGImagePropertyPixelHeight as String] as? Int {
            dims = "\(w)x\(h)"
        }
        // 상위 폴더명으로 출처를 함께 남긴다 (Fixtures = 번들 동봉 / MockImagesReal = 호스트)
        let origin = url.deletingLastPathComponent().lastPathComponent
        return "\(url.lastPathComponent) \(dims) \(data.count / 1024)KB [출처: \(origin)]"
    }

    // MARK: - phys_footprint 샘플러

    /// `DecodeVariantBenchTests`가 동일 계측기를 쓰기 위해 internal (가시성만 변경, 로직 동일)
    final class FootprintSampler: @unchecked Sendable {
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

    // MARK: - 풀디코드 대조군: 전체 디코드 + 재인코딩

    /// 풀디코드 대조군: 다운샘플 없이 원본 전체를 UIImage로 디코드(풀사이즈 비트맵 상주) 후 JPEG 재인코딩.
    /// 주의: 리팩토링 전 앱의 재현이 아니다 — 레거시는 픽셀을 디코드하지 않고 원본을 그대로 업로드했다.
    func test_fullDecodeControl_peakDelta() throws {
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
        print("🧪 [풀디코드 대조군: 전체 디코드+재인코딩]\n" + lines.joined(separator: "\n"))
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

    // MARK: - 다운샘플 옵션 실험: 풀사이즈 디코드(+50MB)의 원인 규명

    /// PhotoMetadataExtractor.downsampledJPEG의 복제본 — 옵션을 바꿔가며 측정하기 위한 실험용
    private func downsampledJPEG(
        data: Data,
        maxPixelSize: CGFloat,
        withTransform: Bool,
        quality: CGFloat = 0.8
    ) -> (data: Data, w: Int, h: Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: withTransform,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, cg, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return (out as Data, cg.width, cg.height)
    }

    /// Transform(EXIF 회전) on/off × maxPixelSize 2048/2016 조합별 피크 delta 비교.
    /// 가설: Transform:true가 JPEG 서브샘플 디코드 경로를 무력화해 풀사이즈 디코드(+50MB)를 유발한다.
    /// 서브샘플 경로를 타면 출력이 2016px(정확히 1/2)로 나오고 delta가 ~12MB대로 떨어질 것.
    func test_downsampleOptions_experiment() throws {
        let url = try Self.fixtureURL()
        let data = try Data(contentsOf: url)
        print("🧪 [입력] \(Self.describe(url, data))")

        // JPEG 코덱 워밍업 (첫 호출의 일회성 +100MB대 스파이크 제거)
        _ = downsampledJPEG(data: data, maxPixelSize: 64, withTransform: false)

        struct Variant { let label: String; let maxPixel: CGFloat; let transform: Bool }
        let variants = [
            Variant(label: "A 현행 — transform:true, max 2048", maxPixel: 2048, transform: true),
            Variant(label: "B transform:false, max 2048", maxPixel: 2048, transform: false),
            Variant(label: "C transform:false, max 2016", maxPixel: 2016, transform: false),
            Variant(label: "D transform:true, max 2016", maxPixel: 2016, transform: true),
        ]

        for v in variants {
            var lines: [String] = []
            for i in 1...3 {
                let sampler = FootprintSampler()
                let baseline = sampler.start()
                let t0 = CFAbsoluteTimeGetCurrent()
                var out = "변환 실패"
                autoreleasepool {
                    if let r = downsampledJPEG(data: data, maxPixelSize: v.maxPixel, withTransform: v.transform) {
                        out = "\(r.w)x\(r.h) \(r.data.count / 1024)KB"
                    } else {
                        XCTFail("변환 실패: \(v.label)")
                    }
                }
                let dt = CFAbsoluteTimeGetCurrent() - t0
                let peak = sampler.stopPeak()
                lines.append("run\(i): +\(mb(peak - baseline))MB, \(String(format: "%.3f", dt))s, out \(out)")
            }
            print("🧪 [\(v.label)]\n" + lines.joined(separator: "\n"))
        }
    }
}
