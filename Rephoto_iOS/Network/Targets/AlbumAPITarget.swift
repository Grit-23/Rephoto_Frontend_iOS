//
//  AlbumAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/19/25.
//

import Foundation
import Moya
import Alamofire

enum AlbumAPITarget {
    case getAlbumList
    case getAlbumInfo(tagId: Int)
}

extension AlbumAPITarget: APITargetType {
    var path: String {
        switch self {
        case .getAlbumList:
            return "/albums"
        case .getAlbumInfo(let tagId):
            return "/albums/\(tagId)/photos"
        }
   
    }
    
    var method: Moya.Method {
        switch self {
        case .getAlbumList, .getAlbumInfo:
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case .getAlbumList, .getAlbumInfo:
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
