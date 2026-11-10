import SwiftUI
import SearchFeature

/// SearchFeature만 단독으로 띄워 확인하는 앱.
/// 지금은 placeholder 텍스트뿐이다. 루트 화면을 연결하고 Project.swift의
/// exampleDependencies에 PreviewSupport를 넣어야 서버 없이 동작을 볼 수 있다.
@main
struct SearchFeatureExampleApp: App {
    var body: some Scene {
        WindowGroup {
            Text("SearchFeature Example")
        }
    }
}
