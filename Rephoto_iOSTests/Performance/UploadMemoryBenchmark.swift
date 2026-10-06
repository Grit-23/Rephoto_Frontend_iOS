//
//  UploadMemoryBenchmark.swift
//  Rephoto_iOSTests
//
//  Created by 김도연 on 7/23/26.
//
//  업로드 전처리 측정: 다운샘플 없는 대조군(전체 디코드 + 재인코딩) vs 현재(ImageIO 다운샘플, #34).
//  처리 시간·출력 크기·메모리 피크를 찍는다. 인용하는 값은 페이로드와 처리 시간이다(메모리는 비교 근거로 쓰지 않음).
//  측정 결과는 BASELINE_RESULTS.md에 기록.
//
//  라벨 정정(2026-08-02): 대조군은 #34 이전 앱의 재현이 아니다. #34 이전 앱은
//  픽셀을 디코드하지 않고 EXIF만 읽은 뒤 받은 사진을 그대로 업로드했다(전처리 상주 ≈ 받은 Data).
//  이 테스트는 "다운샘플하지 않는 표준 구현"의 측정용으로 유지한다.
//
//  측정 방식: XCTMemoryMetric의 "Memory Peak Physical"은 프로세스 전체의 단조증가 피크라
//  셋업 메모리에 오염된다. 대신 task_vm_info.phys_footprint를 폴링해
//  작업 구간의 피크 증가분(delta)을 직접 잰다. 결과는 콘솔의 🧪 라인으로 출력.
//
//  입력: 원본 해상도 사진(JPEG/HEIC). 추출·옵션 실험은 전부(`fixtureURLs()`), 대조군은 가장 큰 한 장(`fixtureURL()`).
//  두 위치를 순서대로 찾는다.
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

    // png 제외 — fixtureURL()이 "가장 큰 파일"을 고르므로 큰 PNG 스크린샷이 섞이면
    // 원본 해상도 사진 대신 선택되어 디코드·재인코딩 조건이 문서 기재와 달라진다
    private static let photoExtensions = ["jpg", "jpeg", "heic"]

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
            · 실기기: Rephoto_iOSTests/Performance/Fixtures/ 에 원본 해상도 사진을 두세요 (테스트 번들에 동봉됨)
            · 시뮬레이터: 리포 루트 MockImagesReal/ 도 가능
            """)
    }

    /// 픽스처 전부를 파일명 순으로 돌려준다. 여러 장을 한 프로세스에서 재기 위함
    /// (`fixtureURL()`은 가장 큰 한 장만 고르므로 사진마다 빌드를 새로 해야 했다).
    /// 번들 동봉본이 있으면 그것만, 없으면 호스트 폴더를 쓴다.
    static func fixtureURLs() throws -> [URL] {
        func unique(_ urls: [URL]) -> [URL] {
            var seen = Set<String>()
            return urls
                .filter { seen.insert($0.lastPathComponent).inserted }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
        let bundled = unique(bundledCandidates())
        if !bundled.isEmpty { return bundled }
        let onHost = unique(hostCandidates())
        if !onHost.isEmpty { return onHost }
        throw XCTSkip("원본 사진 픽스처를 찾지 못했습니다. Fixtures/ 또는 MockImagesReal/ 에 사진을 두세요.")
    }

    /// `PhotoMetadataExtractor`의 목표 크기 계산을 그대로 쓴다(12MP 4032px이면 2016).
    /// 옵션 실험의 D(현재 앱)를 사진 크기와 무관하게 앱 경로와 같게 맞추기 위함.
    static func alignedTargetPixelSize(for data: Data) -> CGFloat {
        var longerSide = 0
        if let src = CGImageSourceCreateWithData(data as CFData, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any] {
            let w = props[kCGImagePropertyPixelWidth as String] as? Int ?? 0
            let h = props[kCGImagePropertyPixelHeight as String] as? Int ?? 0
            longerSide = max(w, h)
        }
        return PhotoMetadataExtractor.targetPixelSize(forLongerSide: longerSide)
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

    // MARK: - 다운샘플 없는 대조군: 전체 디코드 + 재인코딩

    /// 다운샘플 없는 대조군: 원본을 그대로 `UIImage(data:)`로 받아 JPEG로 재인코딩한다.
    ///
    /// 이름 이력(2026-08-03): 종전 `test_fullDecodeControl_peakDelta`. iPhone 14 Pro 측정에서
    /// 이 경로의 피크(9.8MB)가 풀사이즈 RGBA(46.5MB)에 한참 못 미쳐 "풀디코드"라는 이름을 뺐다.
    /// 픽셀 포맷을 못박은 강제 풀디코드는 `DecodeVariantBenchTests.test_C_cgdraw_peakDelta` 쪽이며,
    /// 거기서는 이론값(4032×3024×4 ≈ 46.5MB)에 맞는 값이 나온다. 상세는 BASELINE_RESULTS.md.
    ///
    /// 주의: #34 이전 앱의 재현이 아니다 — #34 이전 앱은 픽셀을 디코드하지 않고 받은 사진을 그대로 업로드했다.
    func test_undownsampledReencode_peakDelta() throws {
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
        print("🧪 [다운샘플 없는 대조군: 전체 디코드+재인코딩]\n" + lines.joined(separator: "\n"))
    }

    // MARK: - 현재 경로: ImageIO 다운샘플 (실제 프로덕션 코드)

    /// 현재 업로드 전처리: PhotoMetadataExtractor.extract — 원본 기반 목표 크기(4032px 원본이면 2016px)로 CGImageSource 썸네일 디코드 + quality 0.8.
    /// `Fixtures/`의 사진을 전부 돈다. 출력 크기는 extract()가 쓴 임시 파일의 실제 바이트 수다(Release에는 DEBUG 로그가 없다).
    func test_current_downsampleExtract_peakDelta() async throws {
        let extractor = PhotoMetadataExtractor()
        for url in try Self.fixtureURLs() {
            let data = try Data(contentsOf: url)
            print("🧪 [입력] \(Self.describe(url, data)) \(data.count)B")

            var lines: [String] = []
            for i in 1...5 {
                let sampler = FootprintSampler()
                let baseline = sampler.start()
                let t0 = CFAbsoluteTimeGetCurrent()
                let item = await extractor.extract(from: data, identifier: "benchmark")
                let dt = CFAbsoluteTimeGetCurrent() - t0
                let peak = sampler.stopPeak()
                XCTAssertNotNil(item, "extract 실패: \(url.lastPathComponent)")
                let outBytes = item.flatMap {
                    try? $0.imageUrl.resourceValues(forKeys: [.fileSizeKey]).fileSize
                } ?? 0
                lines.append("run\(i): peakDelta +\(mb(peak - baseline))MB, \(String(format: "%.4f", dt))s, out \(outBytes)B")
            }
            print("🧪 [current ImageIO 다운샘플]\n" + lines.joined(separator: "\n"))
        }
    }

    // MARK: - 다운샘플 옵션 실험: 풀사이즈 디코드(시뮬레이터 +50MB)의 원인 규명

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

    /// Transform(EXIF 회전) on/off × maxPixelSize 2048 / 경계 정렬값 조합별 처리 시간·출력 비교.
    /// A(#49 이전 앱)는 2048 고정, D(현재 앱)는 `alignedTargetPixelSize`로 사진마다 앱과 같은 목표를 쓴다
    /// (4032px 원본이면 2016). `Fixtures/`의 사진을 전부 돈다.
    /// 네 변형을 한 프로세스에서 이어 돌리므로 변형 간 메모리 비교 근거로는 쓰지 않는다.
    func test_downsampleOptions_experiment() throws {
        for url in try Self.fixtureURLs() {
            let data = try Data(contentsOf: url)
            let aligned = Self.alignedTargetPixelSize(for: data)
            print("🧪 [입력] \(Self.describe(url, data)) \(data.count)B")

            // JPEG 코덱 워밍업 (첫 호출의 일회성 스파이크 제거)
            _ = downsampledJPEG(data: data, maxPixelSize: 64, withTransform: false)

            struct Variant { let label: String; let maxPixel: CGFloat; let transform: Bool }
            let a = Int(aligned)
            let variants = [
                Variant(label: "A #49 이전 — transform:true, max 2048", maxPixel: 2048, transform: true),
                Variant(label: "B transform:false, max 2048", maxPixel: 2048, transform: false),
                Variant(label: "C transform:false, max \(a)", maxPixel: aligned, transform: false),
                Variant(label: "D transform:true, max \(a)", maxPixel: aligned, transform: true),
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
                            XCTFail("변환 실패: \(v.label) · \(url.lastPathComponent)")
                        }
                    }
                    let dt = CFAbsoluteTimeGetCurrent() - t0
                    let peak = sampler.stopPeak()
                    lines.append("run\(i): +\(mb(peak - baseline))MB, \(String(format: "%.4f", dt))s, out \(out)")
                }
                print("🧪 [\(v.label)]\n" + lines.joined(separator: "\n"))
            }
        }
    }
}
