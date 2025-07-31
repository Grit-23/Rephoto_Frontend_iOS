//
//  APITargetType.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/12/25.
//

import Foundation
import Moya

protocol APITargetType: TargetType {}

extension APITargetType {
    var baseURL: URL {
        return URL(string: Config.BASE_URL)!
    }

    var headers: [String: String]? {
        switch task {
        case .requestJSONEncodable, .requestParameters:
            return ["Content-Type": "application/json"]
        case .uploadMultipart:
            return ["Content-Type": "multipart/form-data"]
        default:
            return nil
        }
    }
    
    // 200번대 응답만 유효한 응답으로 간주하고 나머지는 실패로 처리
    var validationType: ValidationType { .successCodes }
}
