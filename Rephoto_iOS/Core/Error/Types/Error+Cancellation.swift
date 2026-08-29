//
//  Error+Cancellation.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

extension Error {
    /// 작업 취소로 인한 실패인지 판별한다.
    ///
    /// 취소는 `CancellationError` 외에 `URLError(.cancelled)`로도 던져진다.
    /// 검색 디바운스처럼 이전 요청을 갈아치우는 경로에서 흔히 발생하며,
    /// **사용자에게 보여줄 실패가 아니므로** 상태를 건드리지 않고 무시해야 한다.
    var isCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}
