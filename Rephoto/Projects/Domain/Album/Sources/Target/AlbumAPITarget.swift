//
//  AlbumAPITarget.swift
//  AlbumDomain
//
//  Created by 김도연 on 8/19/25.
//

import Foundation
import NetworkAdapter

enum AlbumAPITarget {
    case getAlbumList
}

extension AlbumAPITarget: APITargetType {
    var path: String {
        switch self {
        case .getAlbumList:
            return "/albums"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getAlbumList:
            return .get
        }
    }

    var task: RequestTask {
        switch self {
        case .getAlbumList:
            return .plain
        }
    }
}
