//
//  DescriptionAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/19/25.
//


import Foundation
import Moya
import Alamofire

enum DescriptionAPITarget {
    case description(photoId: Int)
}

extension DescriptionAPITarget: APITargetType {
    var path: String {
        switch self {
        case .description(let photoId):
            return "/description/\(photoId)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .description:
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case .description:
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
