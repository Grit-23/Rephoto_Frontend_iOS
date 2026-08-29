//
//  PresentableError.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

/// Alert으로 띄울 에러 한 건.
///
/// ``AppError``(무엇이 실패했나)와 ``ErrorContext``(어디서·어떻게 되돌리나)를 묶는다.
/// 문구·아이콘 같은 표현은 ``ErrorDisplay``가 담당하므로 여기서는 다루지 않는다.
struct PresentableError: Identifiable {

    let id = UUID()
    let error: AppError
    let context: ErrorContext
    let retryAction: (() async -> Void)?

    /// 재시도 버튼 표시 여부 — 에러가 재시도 가능하고 되돌릴 동작이 있을 때만
    var showRetry: Bool {
        error.isRetryable && retryAction != nil
    }

    init(error: AppError, context: ErrorContext) {
        self.error = error
        self.context = context
        self.retryAction = context.retryAction
    }
}

extension PresentableError: Equatable {
    /// 표시 단위가 인스턴스이므로 동일성만 본다.
    static func == (lhs: PresentableError, rhs: PresentableError) -> Bool {
        lhs.id == rhs.id
    }
}
