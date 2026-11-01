//
//  Workspace.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//

import ProjectDescription
import DependencyPlugin

/// 모듈 목록은 `GeneratedModules.swift`의 enum에서 가져온다.
/// 모듈을 추가해도 이 파일은 고치지 않는다 (`make module`이 enum을 다시 만든다).
let projects: [Path] = ["Projects/App"]
    + FeatureModule.allCases.map { .relativeToRoot($0.path) }
    + DomainModule.allCases.map { .relativeToRoot($0.path) }
    + CoreModule.allCases.map { .relativeToRoot($0.path) }
    + SharedModule.allCases.map { .relativeToRoot($0.path) }

let workspace = Workspace(
    name: "Rephoto",
    projects: projects,
    additionalFiles: [
        "Makefile",
        "mise.toml",
        ".gitignore",
        "Scripts/**",
        "Config/Shared.xcconfig",
    ]
)
