//
//  RequestTask+Testing.swift
//  NetworkAdapterTesting
//
//  Created by Doyeon Kim on 6/6/26.
//

import Foundation
import NetworkAdapter

// MARK: - RequestTask 검증 헬퍼

/// APITarget 계약 테스트용 RequestTask 구조 접근자.
///
/// RequestTask는 연관값에 `any Encodable`을 담아 Equatable을 만족시킬 수 없으므로,
/// 케이스 판별과 연관값 추출을 옵셔널 반환으로 감싸 `#require`/`#expect`와 조합해 쓴다.
extension RequestTask {

    /// 바디가 없는 요청인지 여부
    public var isPlain: Bool {
        if case .plain = self { return true }
        return false
    }

    /// `.jsonEncodable`의 바디를 구체 DTO 타입으로 꺼낸다. 케이스나 타입이 다르면 nil.
    public func jsonBody<T: Encodable>(as type: T.Type) -> T? {
        guard case .jsonEncodable(let body) = self else { return nil }
        return body as? T
    }

    /// `.multipart`의 파트 목록을 꺼낸다. 다른 케이스면 nil.
    public var multipartItems: [MultipartFormItem]? {
        guard case .multipart(let items) = self else { return nil }
        return items
    }
}
