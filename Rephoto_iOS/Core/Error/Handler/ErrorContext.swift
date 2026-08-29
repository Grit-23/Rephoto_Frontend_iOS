//
//  ErrorContext.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

/// 에러가 발생한 위치와 재시도 방법을 담는다.
///
/// 같은 `NetworkError`라도 "사진 업로드 실패"와 "태그 추가 실패"는 로그에서 구분되어야 하고,
/// 재시도 동작도 다르다. 그 차이를 에러 타입이 아니라 컨텍스트가 들고 있게 한다.
struct ErrorContext: Equatable {

    /// 에러가 발생한 Feature 이름 (PascalCase — `"Home"`, `"Search"`, `"User"`)
    let feature: String

    /// 해당 Feature 안에서의 동작 (camelCase 동사 — `"fetchPhotos"`, `"addTag"`)
    let action: String

    /// 재시도 동작. `nil`이면 재시도 버튼이 표시되지 않는다.
    ///
    /// - Important: 순환 참조를 피하려면 `[weak self]`로 캡처한다.
    let retryAction: (() async -> Void)?

    init(
        feature: String,
        action: String,
        retryAction: (() async -> Void)? = nil
    ) {
        self.feature = feature
        self.action = action
        self.retryAction = retryAction
    }

    /// 클로저는 비교 대상에서 제외하고 발생 위치만 본다.
    static func == (lhs: ErrorContext, rhs: ErrorContext) -> Bool {
        lhs.feature == rhs.feature && lhs.action == rhs.action
    }
}
