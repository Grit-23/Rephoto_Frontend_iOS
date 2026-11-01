//
//  Settings+Recommended.swift
//  DependencyPlugin
//
//  Created by Doyeon Kim on 10/30/26.
//

import ProjectDescription

/// 모듈의 기본 액터 격리 (`SWIFT_DEFAULT_ACTOR_ISOLATION`).
///
/// UI를 다루는 모듈(Feature · DesignSystem · App)은 `mainActor`,
/// 나머지(Domain · Core · Foundation)는 `nonisolated`로 둔다.
/// 단일 타깃에서는 한쪽으로만 정할 수 있어 타입마다 `@MainActor`를 붙였다.
public enum ActorIsolation: String {
    case mainActor = "MainActor"
    case nonisolated
}

public let rephotoDestinations: Destinations = [.iPhone]

public let rephotoDeploymentTargets: DeploymentTargets = .iOS("26.0")

/// 모든 프로젝트에 공통으로 적용하는 빌드 설정.
///
/// 기존 `Rephoto_iOS.xcodeproj` 값을 옮겼다. `SWIFT_APPROACHABLE_CONCURRENCY`는
/// 기존에 테스트 타깃만 `YES`였던 것을 전체로 통일한다.
///
/// Tuist는 generate마다 프로젝트를 다시 만들므로 Xcode UI에서 바꾼 설정은 남지 않는다.
/// 설정은 반드시 여기서 바꾼다.
public let rephotoBaseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "5.0",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "MARKETING_VERSION": "1.0",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": "9NLDD768V4",
    "CODE_SIGN_STYLE": "Automatic",
]

public func isolationSettings(_ isolation: ActorIsolation) -> SettingsDictionary {
    ["SWIFT_DEFAULT_ACTOR_ISOLATION": .string(isolation.rawValue)]
}
