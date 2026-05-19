//
//  AuthedProvider+Async.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

import Foundation
import Moya

extension AuthedProvider {
    func request(_ target: UserAPITarget) async throws -> Response {
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
