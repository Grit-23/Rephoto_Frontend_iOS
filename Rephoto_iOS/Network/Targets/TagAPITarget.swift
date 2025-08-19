//
//  TagAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/17/25.
//

import Foundation
import Moya
import Alamofire

enum TagAPITarget {
    case addTag(photoId: Int, tagName: String)                // POST /api/photos/{photoId}/tags
    case getTags(photoId: Int)                                // GET /api/photos/{photoId}/tags
    case updateTag(photoTagId: Int, tagName: String)          // PUT /api/photo-tags/{photoTagId}
    case deleteTag(photoTagId: Int)                           // DELETE /api/photo-tags/{photoTagId}
}

extension TagAPITarget: APITargetType {
    var path: String {
        switch self {
        case .addTag(let photoId, _),
             .getTags(let photoId):
            return "/photos/\(photoId)/tags"
            
        case .updateTag(let photoTagId, _),
             .deleteTag(let photoTagId):
            return "/photo-tags/\(photoTagId)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .addTag:
            return .post
        case .getTags:
            return .get
        case .updateTag:
            return .put
        case .deleteTag:
            return .delete
        }
    }
    
    var task: Task {
        switch self {
        case .addTag(_, let tagName):
            return .requestParameters(
                parameters: ["tagName": tagName],
                encoding: JSONEncoding.default
            )
            
        case .updateTag(_, let tagName):
            return .requestParameters(
                parameters: ["tagName": tagName],
                encoding: JSONEncoding.default
            )
            
        case .getTags, .deleteTag:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        var headers = ["Content-Type" : "application/json"]

        if let accessToken = UserDefaults.standard.string(forKey: "accessToken"), !accessToken.isEmpty {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        
        return headers
    }
}
