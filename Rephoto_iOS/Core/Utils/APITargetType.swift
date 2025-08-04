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
}
