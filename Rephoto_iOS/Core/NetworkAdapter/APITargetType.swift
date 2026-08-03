//
//  APITargetType.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/4/25.
//

import Foundation

/// API 엔드포인트 선언 DSL
///
/// baseURL은 타겟이 아니라 `NetworkAdapter`가 생성자로 주입받아 소유한다 —
/// 테스트에서 스텁 호스트로 갈아끼울 수 있어야 하므로 선언부에 박지 않는다.
/// 상태코드 검증은 NetworkClient(NetworkError.httpError)가 수행한다.
protocol APITargetType {
    var path: String { get }
    var method: HTTPMethod { get }
    var task: RequestTask { get }
    var headers: [String: String]? { get }
}

extension APITargetType {
    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}
