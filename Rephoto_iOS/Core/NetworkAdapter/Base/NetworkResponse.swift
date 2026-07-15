//
//  NetworkResponse.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation

/// 네트워크 응답 (상태코드 + 바디)
struct NetworkResponse {
    let statusCode: Int
    let data: Data
}
