//
//  RephotoApp.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//

import SwiftUI
import RephotoFoundation

/// Tuist 전환 중 임시 진입점.
///
/// 화면은 PR 4에서 기존 `ContentView` · `RephotoTabView`로 바뀐다.
/// 지금은 RephotoFoundation 링크와 xcconfig → Info.plist의 BASE_URL 주입이 되는지만 보여준다.
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
            }
        }
    }
}
