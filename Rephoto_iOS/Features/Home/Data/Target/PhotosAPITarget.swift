//
//  PhotosAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

enum PhotosAPITarget {
    case getAllPhotos
    case deletePhoto(photoId: Int)
    case s3Upload(file: Data)
    case savePhotosBatch(request: PhotoBatchRequestDTO)
}

extension PhotosAPITarget: APITargetType {
    var path: String {
        switch self {
        case .getAllPhotos:
            return "/photos"
        case .deletePhoto(let photoId):
            return "/photos/\(photoId)"
        case .s3Upload:
            return "/photos/s3"
        case .savePhotosBatch:
            return "/photos/batch"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getAllPhotos:
            return .get
        case .deletePhoto:
            return .delete
        case .s3Upload, .savePhotosBatch:
            return .post
        }
    }

    var task: RequestTask {
        switch self {
        case .getAllPhotos, .deletePhoto:
            return .plain
        case .s3Upload(let file):
            let item = MultipartFormItem(
                data: file,
                name: "file",
                fileName: "photo.jpg",
                mimeType: "image/jpeg"
            )
            return .multipart([item])
        case .savePhotosBatch(let request):
            return .jsonEncodable(request)
        }
    }

    var headers: [String: String]? {
        switch self {
        case .s3Upload:
            return nil // NetworkAdapter가 multipart boundary 자동 설정
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
