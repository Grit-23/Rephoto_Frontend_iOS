//
//  PhotoMetadataExtractor.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

struct PhotoMetadataExtractor: PhotoMetadataExtractorProtocol {
    func extract(from imageData: Data, identifier: String?) async -> PhotoUploadItem? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
        else { return nil }

        let exif = properties["{Exif}"] as? [String: Any]
        let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any]

        // 촬영 시간
        var createdAt = Date()
        if let raw = exif?["DateTimeOriginal"] as? String,
           let date = DateFormatter.exifOriginal.date(from: raw) {
            createdAt = date
        }

        let latitude = gps?["Latitude"] as? Double ?? 0.0
        let longitude = gps?["Longitude"] as? Double ?? 0.0

        // 파일 이름
        // identifier는 "UUID/L0/001"처럼 슬래시를 포함할 수 있어, 그대로 쓰면
        // appendingPathComponent가 하위 경로로 해석해 임시 파일 저장이 실패한다.
        let rawName = identifier ?? UUID().uuidString
        let fileName = rawName.replacingOccurrences(of: "/", with: "_")

        // 업로드 전 다운샘플 + JPEG 압축 (원본 그대로 올리던 것을 ImageIO로 교체)
        // 위치/촬영시간은 위에서 EXIF로 이미 추출했으므로, 압축본에 메타가 빠져도 무방
        //
        // 목표 크기는 JPEG 1/2ⁿ 서브샘플 디코드 경계에 맞춰 동적 계산한다.
        // 경계에 안 맞으면(예: 4032px 원본에 2048 요청) ImageIO가 풀사이즈로 디코드한 뒤
        // 축소해서 피크 메모리가 2배로 뛴다 — UploadMemoryBenchmark 실측 +50MB → +28MB
        let pxW = properties[kCGImagePropertyPixelWidth as String] as? Int ?? 0
        let pxH = properties[kCGImagePropertyPixelHeight as String] as? Int ?? 0
        let longerSide = max(pxW, pxH)
        var targetPixelSize: CGFloat = longerSide > 0 ? CGFloat(longerSide) : 2016
        while targetPixelSize > 2048 { targetPixelSize /= 2 }

        guard let compressed = downsampledJPEG(from: source, maxPixelSize: targetPixelSize, quality: 0.8) else {
            return nil
        }

        #if DEBUG
        let beforeKB = imageData.count / 1024
        let afterKB = compressed.count / 1024
        let ratio = beforeKB == 0 ? 0 : afterKB * 100 / beforeKB
        print("📷 [압축] \(pxW)x\(pxH) → 목표 \(Int(targetPixelSize))px  \(beforeKB)KB → \(afterKB)KB  (\(ratio)%)")
        #endif

        // 임시 파일 저장 (실패 시 업로드 불가하므로 nil 반환)
        let destURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName).jpg")
        do {
            try compressed.write(to: destURL)
        } catch {
            return nil
        }

        return PhotoUploadItem(
            latitude: latitude,
            longitude: longitude,
            imageUrl: destURL,
            createdAt: DateFormatter.serverISO.string(from: createdAt),
            fileName: destURL.lastPathComponent
        )
    }

    /// ImageIO로 디코드 시점에 다운샘플 → JPEG 인코딩.
    /// 주의: 서브샘플(1/2ⁿ) 디코드 경로는 `원본/2ⁿ ≥ maxPixelSize`일 때만 성립한다.
    /// 경계에 안 맞는 값을 넘기면 풀사이즈 디코드 후 축소로 떨어져 피크 메모리 이점이 사라지므로
    /// (UploadMemoryBenchmark 실측), 호출부에서 원본 크기 기반으로 경계에 맞는 목표를 계산해 넘긴다.
    private func downsampledJPEG(
        from source: CGImageSource,
        maxPixelSize: CGFloat,
        quality: CGFloat
    ) -> Data? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true, // EXIF 회전 반영 (세로 사진 눕는 것 방지)
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let outData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outData, UTType.jpeg.identifier as CFString, 1, nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(
            destination, cgImage,
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { return nil }
        return outData as Data
    }
}
