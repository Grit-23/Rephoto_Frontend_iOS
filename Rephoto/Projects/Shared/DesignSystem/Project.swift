import ProjectDescription
import DependencyPlugin

/// 디자인 시스템 — 색 토큰(`Colors.xcassets`) · 공용 컴포넌트 · 에러 표시(`ErrorHandler` · `ErrorStateView`).
/// UI 모듈이므로 Shared 계층이지만 기본 격리는 MainActor다.
///
/// `ErrorHandler`의 상태 전이는 Tests에서, 화면은 각 Feature의 Example 앱에서 확인한다.
let project = Project.shared(
    .DesignSystem,
    hasTests: true,
    dependencies: [
        .shared(.Foundation),
        .external(name: "Nuke"),
        .external(name: "NukeUI"),
    ],
    testsDependencies: [
        .shared(.Foundation),
    ],
    resources: ["Resources/**"],
    isolation: .mainActor,
    settings: [
        // 정적 프레임워크의 에셋은 별도 리소스 번들에 들어가므로 Xcode 생성 심벌 대신
        // Colors.swift의 공개 접근자가 번들을 지정한다. 생성 심벌과 이름이 겹치지 않게 끈다.
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "NO",
    ]
)
