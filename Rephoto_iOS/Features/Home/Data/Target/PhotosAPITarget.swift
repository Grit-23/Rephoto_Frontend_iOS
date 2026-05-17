//
//  PhotosAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import Moya
import Alamofire

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

    var method: Moya.Method {
        switch self {
        case .getAllPhotos:
            return .get
        case .deletePhoto:
            return .delete
        case .s3Upload, .savePhotosBatch:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .getAllPhotos, .deletePhoto:
            return .requestPlain
        case .s3Upload(let file):
            let formData = MultipartFormData(
                provider: .data(file),
                name: "file",
                fileName: "photo.jpg",
                mimeType: "image/jpeg"
            )
            return .uploadMultipart([formData])
        case .savePhotosBatch(let request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        var headers: [String: String] = [:]

        if let accessToken = UserDefaults.standard.string(forKey: "accessToken"), !accessToken.isEmpty {
            headers["Authorization"] = "Bearer \(accessToken)"
        }

        switch self {
        case .s3Upload:
            break // Moya가 multipart boundary 포함하여 자동 설정
        default:
            headers["Content-Type"] = "application/json"
        }

        return headers
    }
}
