//
//  RephotoApp.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//

import SwiftUI
import RephotoFoundation
import DesignSystem

/// Tuist 전환 중 임시 진입점.
///
/// 화면은 PR 4에서 기존 `ContentView` · `RephotoTabView`로 바뀐다.
/// 지금은 모듈 링크가 되는지만 보여준다 — RephotoFoundation의 `Config.baseURL`(xcconfig → Info.plist 주입)과
/// DesignSystem의 `ErrorStateView`(정적 프레임워크 리소스 번들의 색 `mainGreen` 포함).
@main
struct RephotoApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 8) {
                Text("Rephoto")
                    .font(.largeTitle.bold())
                Text(Config.baseURL)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                ErrorStateView(error: .network(.noNetwork)) {}
            }
        }
    }
}
