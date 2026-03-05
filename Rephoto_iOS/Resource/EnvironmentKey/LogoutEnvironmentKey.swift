//
//  LogoutEnvironmentKey.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 3/4/26.
//

import SwiftUI

struct LogoutEnvironmentKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var logout: () -> Void {
        get { self[LogoutEnvironmentKey.self] }
        set { self[LogoutEnvironmentKey.self] = newValue }
    }
}
