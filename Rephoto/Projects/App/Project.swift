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
            // App만 구현 모듈(Domain · Feature)과 Factory를 링크한다. Feature는 Interface만 본다.
            dependencies: [
                .shared(.Foundation),
                .shared(.DesignSystem),
                .core(implementation: .NetworkAdapter),
                .domain(interface: .Photo),
                .domain(interface: .Tag),
                .domain(implementation: .Photo),
                .domain(implementation: .Tag),
                .domain(implementation: .PreviewSupport),
                .feature(implementation: .Home),
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
    ]
)
