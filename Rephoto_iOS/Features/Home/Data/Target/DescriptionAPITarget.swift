//
//  DescriptionAPITarget.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

enum DescriptionAPITarget {
    case getDescription(photoId: Int)
}

extension DescriptionAPITarget: APITargetType {
    var path: String {
        switch self {
        case .getDescription(let photoId):
            return "/photos/\(photoId)/description"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getDescription:
            return .get
        }
    }

    var task: RequestTask {
        switch self {
        case .getDescription:
            return .plain
        }
    }

}
