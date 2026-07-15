//
//  SearchAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/4/25.
//

import Foundation

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

    var method: HTTPMethod {
        switch self {
        case .search:
            return .post
        }
    }

    var task: RequestTask {
        switch self {
        case .search(let query):
            return .jsonEncodable(SearchRequestDTO(query: query))
        }
    }

}
