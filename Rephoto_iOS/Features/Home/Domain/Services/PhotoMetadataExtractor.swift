//
//  PhotoMetadataExtractor.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import PhotosUI
import SwiftUI

struct PhotoMetadataExtractor {
    static func extract(from item: PhotosPickerItem) async -> PhotoUploadItem? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
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
        let fileName = item.itemIdentifier ?? UUID().uuidString

        // 임시 파일 저장
        let destURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName).jpg")
        try? data.write(to: destURL)

        return PhotoUploadItem(
            latitude: latitude,
            longitude: longitude,
            imageUrl: destURL.absoluteString,
            createdAt: DateFormatter.serverISO.string(from: createdAt),
            fileName: destURL.lastPathComponent
        )
    }
}
