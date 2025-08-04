//
//  MoyaProvider.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/4/25.
//

import Foundation
import Moya

extension MoyaProvider {
    func requestAsync(
        _ target: Target,
        queue: DispatchQueue? = nil
    ) async throws -> Response {
        try await withCheckedThrowingContinuation { cont in
            self.request(target, callbackQueue: queue) { result in
                switch result {
                case .success(let resp): cont.resume(returning: resp)
                case .failure(let err):   cont.resume(throwing: err)
                }
            }
        }
    }
}
