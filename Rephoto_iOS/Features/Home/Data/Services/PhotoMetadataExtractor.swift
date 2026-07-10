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
        guard let compressed = downsampledJPEG(from: source, maxPixelSize: 2048, quality: 0.8) else {
            return nil
        }

        #if DEBUG
        let beforeKB = imageData.count / 1024
        let afterKB = compressed.count / 1024
        let pxW = properties[kCGImagePropertyPixelWidth as String] as? Int ?? 0
        let pxH = properties[kCGImagePropertyPixelHeight as String] as? Int ?? 0
        let ratio = beforeKB == 0 ? 0 : afterKB * 100 / beforeKB
        print("📷 [압축] \(pxW)x\(pxH)  \(beforeKB)KB → \(afterKB)KB  (\(ratio)%)")
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
    /// `UIImage(data:).jpegData()`는 풀해상도 비트맵을 메모리에 올려서 4000x3000 기준 ~36MB가 튀지만,
    /// `CGImageSourceCreateThumbnailAtIndex`는 목표 크기로만 디코드해 피크 메모리를 크게 낮춘다.
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
