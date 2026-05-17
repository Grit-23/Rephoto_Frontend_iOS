//
//  MoyaProvider+Async.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation
import Moya

extension MoyaProvider {
    func request(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
