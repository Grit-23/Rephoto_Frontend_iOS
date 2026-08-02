//
//  DecodeVariantBenchTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 8/2/26.
//
//  디코드 변형별 메모리 피크 대조 — "다운샘플 없는 대조군 +19MB" 수치의 원인 규명용.
//
//  문제: 4032×3024 원본을 풀사이즈 RGBA(8bit×4ch)로 디코드하면 이론상 ≈46.5MB인데,
//  기존 `UploadMemoryBenchmark.test_undownsampledReencode_peakDelta`는 그 절반도 나오지 않는다.
//
//  가설 두 개를 가른다.
//   (a) 대조군이 UIImage lazy decoding 탓에 실제로는 픽셀을 디코드하지 않았다
//   (b) 하드웨어/플랫폼 디코더가 서브샘플 YUV(1.5~2B/px)로 풀었다
//
//  이 테스트는 판정을 내리지 않는다. 변형별 피크 delta를 찍어 비교 재료만 남긴다.
//  해석은 실기기 + Release 측정 결과로 한다 (BASELINE_RESULTS.md의 "측정 환경" 참조).
//
//  ── 측정 설계 (2026-08-02 실기기 1차 측정에서 드러난 결함을 반영해 개정) ──
//
//  1) 변형마다 독립 테스트 메서드로 분리한다.
//     한 메서드에서 A→B→C→D를 연달아 돌리면 앞 변형이 남긴 상주 메모리가 뒤 변형의
//     baseline을 밀어올려 순서 의존성이 생긴다. `-only-testing`으로 하나씩 돌리면
//     그 영향까지 없앨 수 있다.
//
//  2) 집계는 중앙값이 아니라 **max**를 쓴다.
//     phys_footprint는 free() 직후 바로 내려가지 않고, 프레임워크가 디코드 결과를
//     내부 캐시에 들고 있기도 한다. 그러면 2회차부터는 보유/캐시된 페이지를 재사용해
//     delta가 +0.0MB로 찍힌다. 이 0.0은 "메모리를 안 썼다"가 아니라 "못 쟀다"이므로,
//     중앙값을 쓰면 유효 샘플이 통째로 버려진다. 피크 측정에서는 max가 맞다.
//
//  3) 워밍업은 **변형 자신이 아닌** 64px 썸네일 디코드로 한다.
//     JPEG 코덱 최초 사용 비용은 걷어내되, 변형 자신을 미리 돌리면 그 변형의
//     디코드 캐시까지 채워져 이후 측정이 전부 0.0이 된다 (1차 측정에서 B가 그랬다).
//
//  입력·계측기는 `UploadMemoryBenchmark`와 공유한다 (동일 조건 보장).
//  픽스처가 없으면 자동 스킵 — 탐색 경로는 `UploadMemoryBenchmark.fixtureURL()` 참조.
//  Rephoto_Performance 플랜 전용 — PR 게이트(Rephoto_iOS 플랜)에서는 skip된다.
//

import XCTest
import UIKit
import ImageIO
import CoreGraphics

final class DecodeVariantBenchTests: XCTestCase {

    private typealias Sampler = UploadMemoryBenchmark.FootprintSampler

    private let repeatCount = 5

    // MARK: - 변형 (메서드명 앞의 A~D는 단독 실행 시 지정 편의를 위한 것)

    /// A: `UIImage(data:)` 생성만 — 디코드를 강제하지 않는다 (lazy decoding 유지)
    func test_A_lazy_peakDelta() throws {
        try measureVariant("A_lazy") { data in
            UIImage(data: data)
        }
    }

    /// B: `preparingForDisplay()` — UIKit에게 즉시 디코드를 요청한다 (플랫폼이 고른 픽셀 포맷)
    func test_B_prepared_peakDelta() throws {
        try measureVariant("B_prepared") { data in
            UIImage(data: data)?.preparingForDisplay()
        }
    }

    /// C: CGImageSource → RGBA 8bit CGContext draw — 픽셀 포맷을 우리가 못박은 강제 풀디코드.
    /// 4032×3024이면 컨텍스트 버퍼만 4032×3024×4 ≈ 46.5MB.
    func test_C_cgdraw_peakDelta() throws {
        try measureVariant("C_cgdraw") { data in
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(
                    source, 0,
                    [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
                  )
            else { return nil }

            let width = cgImage.width
            let height = cgImage.height
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return context.makeImage()
        }
    }

    /// D: `UploadMemoryBenchmark.test_undownsampledReencode_peakDelta`의 작업 구간 복사본.
    /// 원본은 손대지 않는다 — 동일 계측기로 A/B/C와 같은 축에서 비교하기 위한 사본이다.
    func test_D_undownsampled_peakDelta() throws {
        // 재인코딩 결과 검증은 측정 구간 밖에서 한다 — XCTAssert 자체가
        // 계측 구간에 섞이지 않도록 바이트 수만 받아 나온다.
        var encodedBytes = 0
        try measureVariant("D_undownsampled") { data in
            guard let image = UIImage(data: data) else { return nil }
            encodedBytes = image.jpegData(compressionQuality: 1.0)?.count ?? 0
            return image
        }
        XCTAssertGreaterThan(encodedBytes, 0, "JPEG 재인코딩이 바이트를 만들지 못했다")
    }

    // MARK: - 측정 하네스

    private func measureVariant(
        _ label: String,
        _ body: @escaping (Data) -> AnyObject?
    ) throws {
        let url = try UploadMemoryBenchmark.fixtureURL()
        let data = try Data(contentsOf: url)
        print("🧪 [입력] \(UploadMemoryBenchmark.describe(url, data))")

        warmUpCodec(with: data)

        var deltas: [UInt64] = []
        var producedCount = 0
        for _ in 1...repeatCount {
            var produced = false
            deltas.append(peakDelta {
                let object = body(data)
                produced = object != nil
                return object
            })
            if produced { producedCount += 1 }
        }

        let runs = deltas.map { "+\(mb($0))MB" }.joined(separator: ", ")
        let peak = deltas.max() ?? 0
        // max가 대표값. 개별 run도 함께 남겨 캐시로 인한 0.0 패턴이 보이게 한다.
        print("🧪 [\(label)] max: \(mb(peak))MB  (runs: \(runs))")

        // 변형이 nil을 반환하면 delta가 0으로 찍히고 "메모리를 안 썼다"로 오독된다.
        // 실제로는 디코드/컨텍스트 생성 실패이므로 반드시 실패로 드러내야 한다.
        XCTAssertEqual(producedCount, repeatCount,
                       "\(label): \(repeatCount)회 중 \(producedCount)회만 객체를 만들었다 — 측정값 무효")
    }

    /// JPEG 코덱 최초 사용 비용만 걷어낸다. 변형 자신을 돌리지 않는 것이 핵심 —
    /// 그러면 변형의 디코드 캐시가 채워져 이후 측정이 전부 0.0이 된다.
    private func warmUpCodec(with data: Data) {
        autoreleasepool {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }
            _ = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 64
            ] as CFDictionary)
        }
    }

    /// `body`가 만든 객체를 계측 구간 끝까지 살려둔 채 phys_footprint 피크 증가분을 잰다.
    ///
    /// `stopPeak()`을 `withExtendedLifetime` 안에서 호출하는 게 핵심이다.
    /// 밖에서 부르면 옵티마이저가 마지막 사용 직후 객체를 해제해버려 피크를 놓칠 수 있다
    /// (Release `-O`에서 특히).
    private func peakDelta(_ body: () -> AnyObject?) -> UInt64 {
        var delta: UInt64 = 0
        autoreleasepool {
            let sampler = Sampler()
            let baseline = sampler.start()
            let object = body()
            withExtendedLifetime(object) {
                let peak = sampler.stopPeak()
                delta = peak > baseline ? peak - baseline : 0
            }
        }
        return delta
    }

    private func mb(_ bytes: UInt64) -> String {
        String(format: "%.1f", Double(bytes) / 1_048_576)
    }
}
