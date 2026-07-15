//
//  APITargetType.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/4/25.
//

import Foundation

/// API 엔드포인트 선언 DSL
///
/// 상태코드 검증은 NetworkClient(NetworkError.httpError)가 수행한다.
protocol APITargetType {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var task: RequestTask { get }
    var headers: [String: String]? { get }
}

extension APITargetType {
    var baseURL: URL {
        guard let url = URL(string: Config.baseURL) else {
            fatalError("Invalid Base URL")
        }
        return url
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}
