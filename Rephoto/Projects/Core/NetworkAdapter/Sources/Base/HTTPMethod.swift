//
//  HTTPMethod.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation

/// HTTP 요청 메서드
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
