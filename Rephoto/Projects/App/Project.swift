//
//  Project.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//

import ProjectDescription
import DependencyPlugin

/// 앱 타깃. 모든 구현 모듈을 조립 · 주입하는 유일한 곳이다.
///
/// Info.plist와 번들 ID는 기존 `Rephoto_iOS.xcodeproj` 값을 옮겼다.
/// 두 프로젝트의 번들 ID가 같으므로 시뮬레이터에는 마지막에 설치한 쪽 하나만 남는다.
let sharedConfig: Path = .relativeToRoot("Config/Shared.xcconfig")

let project = Project(
    name: "Rephoto",
    // 앱 실행과 전체 모듈 테스트를 묶는 Rephoto 스킴은 Workspace.swift에서 정의한다.
    options: .options(automaticSchemesOptions: .disabled),
    settings: .settings(base: rephotoBaseSettings),
    targets: [
        .target(
            name: "Rephoto",
            destinations: rephotoDestinations,
            product: .app,
            bundleId: "com.dodle.Rephoto-iOS",
            deploymentTargets: rephotoDeploymentTargets,
            infoPlist: .extendingDefault(with: [
                "BASE_URL": "$(BASE_URL)",
                "NSPhotoLibraryUsageDescription": "사진권한",
                "NSFaceIDUsageDescription": "숨겨진 민감한 사진을 보려면 Face ID 인증이 필요해요.",
                "UIUserInterfaceStyle": "Light",
                "UILaunchScreen": [:],
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": true,
                ],
                "UIApplicationSupportsIndirectInputEvents": true,
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            // App만 구현 모듈(Domain · Feature)과 Factory를 링크한다. Feature는 Interface만 본다.
            dependencies: [
                .shared(.Foundation),
                .shared(.DesignSystem),
                .core(implementation: .NetworkAdapter),
                .domain(interface: .Album),
                .domain(interface: .Photo),
                .domain(interface: .Tag),
                .domain(interface: .User),
                .domain(implementation: .Album),
                .domain(implementation: .Photo),
                .domain(implementation: .Tag),
                .domain(implementation: .User),
                .domain(implementation: .PreviewSupport),
                .feature(interface: .Home),
                .feature(implementation: .Home),
                .feature(implementation: .Search),
                .feature(implementation: .User),
                .external(name: "Factory"),
            ],
            settings: .settings(
                base: isolationSettings(.mainActor),
                configurations: [
                    .debug(name: .debug, xcconfig: sharedConfig),
                    .release(name: .release, xcconfig: sharedConfig),
                ]
            )
        ),
        // 성능 벤치마크. 실기기는 호스트 앱이 있는 테스트만 돌릴 수 있어 모듈 Tests가 아니라 앱에 붙인다.
        // Rephoto_Performance 플랜으로만 돈다. Fixtures는 개인 사진이라 커밋하지 않으며, 없으면 skip된다.
        .target(
            name: "RephotoPerformanceTests",
            destinations: rephotoDestinations,
            product: .unitTests,
            bundleId: "com.dodle.rephoto.RephotoPerformanceTests",
            deploymentTargets: rephotoDeploymentTargets,
            sources: ["PerformanceTests/**"],
            resources: ["PerformanceTests/Fixtures/**"],
            dependencies: [
                .target(name: "Rephoto"),
                .domain(interface: .Photo),
                .domain(implementation: .Photo),
            ],
            settings: .settings(base: isolationSettings(.nonisolated))
        ),
    ]
)
