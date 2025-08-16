//
//  PhotosAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/14/25.
//

import SwiftUI
import Moya
import Alamofire

enum PhotosAPITarget {
    case s3Upload(file: Data)                           // S3 업로드
    case savePhotosBatch(request: PhotoBatchRequestDto) // 초기 사진 일괄 업로드
    case getPhoto(photoId: Int)                         // 단일 사진 조회
    case deletePhoto(photoId: Int)                      // 사진 삭제
    case getAllPhotos                                   // 전체 사진 조회
    case getWarningPhotos                               // 민감 사진 조회
}

extension PhotosAPITarget: APITargetType {
    var path: String {
        switch self {
        case .s3Upload:
            return "/files/upload"
        case .savePhotosBatch:
            return "/photos/batch"
        case .getPhoto(let photoId):
            return "/photos/\(photoId)"
        case .deletePhoto(let photoId):
            return "/photos/\(photoId)"
        case .getAllPhotos:
            return "/photos"
        case .getWarningPhotos:
            return "/photos/warning"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .s3Upload, .savePhotosBatch:
            return .post
        case .getPhoto, .getAllPhotos, .getWarningPhotos:
            return .get
        case .deletePhoto:
            return .delete
        }
    }
    
    var task: Task {
        switch self {
        case let .s3Upload(fileData):
            let formData = MultipartFormData(provider: .data(fileData),
                                             name: "file",
                                             mimeType: "image/jpeg")
            return .uploadMultipart([formData])
            
        case let .savePhotosBatch(request):
            return .requestJSONEncodable(request)
            
        case .getPhoto, .deletePhoto, .getAllPhotos, .getWarningPhotos:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        var headers: [String: String] = [:]
        
        if let accessToken = UserDefaults.standard.string(forKey: "accessToken"), !accessToken.isEmpty {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        
        switch self {
        case .s3Upload:
            // Content-Type 자동 설정 (Moya가 multipart/form-data 붙여줌)
            break
        case .savePhotosBatch, .getPhoto, .deletePhoto, .getAllPhotos, .getWarningPhotos:
            headers["Content-Type"] = "application/json"
        }
        
        return headers
    }
}
