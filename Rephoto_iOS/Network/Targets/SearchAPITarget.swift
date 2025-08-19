//
//  SearchAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/4/25.
//

import Foundation
import Moya
import Alamofire

enum SearchAPITarget {
    case search(query: String)
}

extension SearchAPITarget: APITargetType {
    var path: String {
        switch self {
        case .search: 
            return "/search"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .search:
            return .post
        }
    }
    
    var task: Task {
        switch self {
        case .search(let query):
            return .requestParameters(parameters: ["query": query], encoding: JSONEncoding.default)
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
