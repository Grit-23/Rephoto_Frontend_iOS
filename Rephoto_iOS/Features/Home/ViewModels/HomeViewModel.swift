//
//  HomeViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import Observation
import Moya
import PhotosUI
import Photos
import UIKit

@Observable
class HomeViewModel {
    var images: [HomeModel] = []
    var imageUrl: String = ""

    var isWarningsCount: Int { images.count(where: { $0.isSensitive }) }

    private let provider = MoyaProvider<PhotosAPITarget>()

    init() {
        fetchPhotos()
    }

    // MARK: - 목록 조회 (콜백)
    func fetchPhotos() {
        provider.request(.getAllPhotos) { result in
            switch result {
            case .success(let response):
                do {
                    let dtos = try JSONDecoder().decode([PhotoResponseDto].self, from: response.data)
                    let mapped = dtos.map { $0.toHomeModel() }
                    DispatchQueue.main.async { self.images = mapped }
                } catch {
                    print("❌ decode error:", error)
                }
            case .failure(let error):
                print("❌ network error:", error)
            }
        }
    }

    // MARK: - 선택 → 업로드 → 배치 저장 (콜백 체인)
    func handlePickedItems(items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        let group = DispatchGroup()
        let lock = NSLock()
        var metadatas: [PhotoMetadata] = []

        for item in items {
            group.enter()

            // 1) 이미지 원본 Data 로드 (PHAssetResourceManager)
            loadImageData(from: item) { loadResult in
                switch loadResult {
                case .success(let data):
                    // 2) EXIF 메타 파싱
                    let exif = self.extractExif(from: data)

                    // 3) S3 업로드 (URL 획득)
                    self.uploadS3ForURL(file: data) { uploadResult in
                        switch uploadResult {
                        case .success(let url):
                            // 4) DTO 조립
                            let createdAt = exif.createdAtISO ?? self.isoString(from: Date())
                            let fileName  = self.makeFileName(from: exif, fallbackISO: createdAt)

                            let meta = PhotoMetadata(
                                latitude: exif.lat ?? 0.0,
                                longitude: exif.lon ?? 0.0,
                                imageUrl: url,
                                createdAt: createdAt,
                                fileName: fileName
                            )
                            lock.lock(); metadatas.append(meta); lock.unlock()
                            group.leave()

                        case .failure(let e):
                            print("❌ s3 업로드 실패:", e)
                            group.leave()
                        }
                    }

                case .failure(let e):
                    print("❌ 이미지 로드 실패:", e)
                    group.leave()
                }
            }
        }

        // 5) 모두 끝나면 배치 저장
        group.notify(queue: .main) {
            guard !metadatas.isEmpty else { return }
            self.saveBatch(photos: metadatas) { result in
                switch result {
                case .success:
                    self.fetchPhotos()
                case .failure(let e):
                    print("❌ batch 저장 실패:", e)
                }
            }
        }
    }

    // MARK: - Helpers (모두 콜백)

    /// PhotosPickerItem -> 원본 Data (PHAssetResourceManager 사용, iCloud 허용)
    private func loadImageData(from item: PhotosPickerItem,
                               completion: @escaping (Result<Data, Error>) -> Void) {
        guard let id = item.itemIdentifier else {
            completion(.failure(NSError(domain: "Picker", code: -2,
                                        userInfo: [NSLocalizedDescriptionKey: "itemIdentifier 없음"])))
            return
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = assets.firstObject else {
            completion(.failure(NSError(domain: "Picker", code: -2,
                                        userInfo: [NSLocalizedDescriptionKey: "PHAsset 없음"])))
            return
        }

        // 우선 원본 리소스(.photo / .fullSizePhoto)로 데이터 요청
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto })
                ?? resources.first else {
            completion(.failure(NSError(domain: "Picker", code: -4,
                                        userInfo: [NSLocalizedDescriptionKey: "AssetResource 없음"])))
            return
        }

        let manager = PHAssetResourceManager.default()
        let opts = PHAssetResourceRequestOptions()
        opts.isNetworkAccessAllowed = true

        var buffer = Data()
        manager.requestData(for: resource, options: opts, dataReceivedHandler: { chunk in
            buffer.append(chunk)
        }, completionHandler: { error in
            if error != nil {
                // 실패 시 옛 방식으로 한번 더 시도 (이미지 데이터 & 방향)
                self.requestImageDataFallback(asset: asset, completion: completion)
                return
            }

            // 업로드는 JPEG가 안정적 → 가능한 경우 JPEG로 통일
            if let ui = UIImage(data: buffer),
               let jpeg = ui.jpegData(compressionQuality: 0.9) {
                completion(.success(jpeg))
            } else {
                completion(.success(buffer))
            }
        })
    }

    /// PHImageManager fallback (혹시 resource 경로 실패했을 때)
    private func requestImageDataFallback(asset: PHAsset,
                                          completion: @escaping (Result<Data, Error>) -> Void) {
        let opts = PHImageRequestOptions()
        opts.isSynchronous = false
        opts.isNetworkAccessAllowed = true
        opts.deliveryMode = .highQualityFormat
        opts.version = .original

        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: opts) { data, _, _, error in
            if let error = error {
                completion(.failure(error as! Error)); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Picker", code: -3,
                                            userInfo: [NSLocalizedDescriptionKey: "이미지 데이터 nil"])))
                return
            }
            if let ui = UIImage(data: data),
               let jpeg = ui.jpegData(compressionQuality: 0.9) {
                completion(.success(jpeg))
            } else {
                completion(.success(data))
            }
        }
    }

    /// S3 업로드 후 URL 반환 (콜백)
    private func uploadS3ForURL(file: Data,
                                completion: @escaping (Result<String, Error>) -> Void) {
        provider.request(.s3Upload(file: file)) { result in
            switch result {
            case .success(let response):
                print(response.data)
                do {
                    let dto = try JSONDecoder().decode(S3UploadResponseDto.self, from: response.data)
                    completion(.success(dto.url))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// 배치 저장 (콜백)
    private func saveBatch(photos: [PhotoMetadata],
                           completion: @escaping (Result<Void, Error>) -> Void) {
        let req = PhotoBatchRequestDto(photos: photos)
        provider.request(.savePhotosBatch(request: req)) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// EXIF에서 위경도/촬영시각 ISO 파싱 (동기)
    private func extractExif(from data: Data) -> (lat: Double?, lon: Double?, createdAtISO: String?) {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] else {
            return (nil, nil, nil)
        }

        var lat: Double?
        var lon: Double?

        if let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
            if let rawLat = gps[kCGImagePropertyGPSLatitude] as? Double,
               let ref = gps[kCGImagePropertyGPSLatitudeRef] as? String {
                lat = (ref == "S") ? -rawLat : rawLat
            }
            if let rawLon = gps[kCGImagePropertyGPSLongitude] as? Double,
               let ref = gps[kCGImagePropertyGPSLongitudeRef] as? String {
                lon = (ref == "W") ? -rawLon : rawLon
            }
        }

        var iso: String?
        if let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let dt = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
            iso = exifStringToISO(dt) // "yyyy:MM:dd HH:mm:ss" -> ISO
        }

        return (lat, lon, iso)
    }

    private func exifStringToISO(_ s: String) -> String? {
        let fin = DateFormatter()
        fin.locale = Locale(identifier: "en_US_POSIX")
        fin.timeZone = TimeZone(secondsFromGMT: 0)
        fin.dateFormat = "yyyy:MM:dd HH:mm:ss"
        guard let d = fin.date(from: s) else { return nil }
        return isoString(from: d)
    }

    private func isoString(from date: Date) -> String {
        let f = DateFormatter()
        f.calendar = .init(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f.string(from: date)
    }

    private func makeFileName(from exif: (lat: Double?, lon: Double?, createdAtISO: String?),
                              fallbackISO: String) -> String {
        let base = exif.createdAtISO ?? fallbackISO
        let safe = base
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "T", with: "_")
            .replacingOccurrences(of: " ", with: "")
        return "photo_\(safe).jpg"
    }
}
