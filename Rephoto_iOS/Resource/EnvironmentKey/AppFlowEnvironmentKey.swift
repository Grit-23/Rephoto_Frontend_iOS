//
//  AppFlowEnvironmentKey.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 3/4/26.
//

import SwiftUI

/// 앱 전역 화면 전환/세션 액션 집합
struct AppFlow {
    let showLogin: () -> Void
    let showMain: () -> Void
    let showSignUp: (String) -> Void
    let logout: () -> Void

    static let noop = AppFlow(
        showLogin: {},
        showMain: {},
        showSignUp: { _ in },
        logout: {}
    )
}

struct AppFlowEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppFlow = .noop
}

extension EnvironmentValues {
    var appFlow: AppFlow {
        get { self[AppFlowEnvironmentKey.self] }
        set { self[AppFlowEnvironmentKey.self] = newValue }
    }
}
