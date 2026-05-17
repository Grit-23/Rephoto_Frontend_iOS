//
//  APITargetType.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/4/25.
//

import Foundation
import Moya

protocol APITargetType: TargetType {}

extension APITargetType {
    var baseURL: URL {
        guard let url = URL(string: Config.baseURL) else {
            fatalError("Invalid Base URL")
        }
        return url
    }

    var validationType: ValidationType {
        .successCodes
    }

    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]

        if let accessToken = UserDefaults.standard.string(forKey: "accessToken"), !accessToken.isEmpty {
            headers["Authorization"] = "Bearer \(accessToken)"
        }

        return headers
    }
}
