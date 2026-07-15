//
//  TagAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

enum TagAPITarget {
    case getTags(photoId: Int)
    case addTag(request: AddTagRequestDTO)
    case updateTag(photoTagId: Int, request: UpdateTagRequestDTO)
    case deleteTag(photoTagId: Int)
}

extension TagAPITarget: APITargetType {
    var path: String {
        switch self {
        case .getTags(let photoId):
            return "/photos/\(photoId)/tags"
        case .addTag:
            return "/tags"
        case .updateTag(let photoTagId, _):
            return "/tags/\(photoTagId)"
        case .deleteTag(let photoTagId):
            return "/tags/\(photoTagId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getTags:
            return .get
        case .addTag:
            return .post
        case .updateTag:
            return .put
        case .deleteTag:
            return .delete
        }
    }

    var task: RequestTask {
        switch self {
        case .getTags, .deleteTag:
            return .plain
        case .addTag(let request):
            return .jsonEncodable(request)
        case .updateTag(_, let request):
            return .jsonEncodable(request)
        }
    }

}
