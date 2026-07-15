//
//  AlbumAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/19/25.
//

import Foundation

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

    var method: HTTPMethod {
        switch self {
        case .getAlbumList, .getAlbumInfo:
            return .get
        }
    }

    var task: RequestTask {
        switch self {
        case .getAlbumList, .getAlbumInfo:
            return .plain
        }
    }

}
