//
//  TargetDependency+Modules.swift
//  DependencyPlugin
//
//  Created by Doyeon Kim on 10/30/26.
//

import ProjectDescription

// MARK: - 타깃 이름 규칙

// 모듈 enum은 `GeneratedModules.swift`에 있고, 이름 규칙은 여기 한 곳에서만 정한다.
// 매니페스트는 문자열로 타깃 이름이나 경로를 쓰지 않는다.

extension FeatureModule {
    public var name: String { String(describing: self) }
    public var path: String { "Projects/Feature/\(name)" }

    public var interfaceTarget: String { "\(name)FeatureInterface" }
    public var implementationTarget: String { "\(name)Feature" }
    public var testingTarget: String { "\(name)FeatureTesting" }
    public var testsTarget: String { "\(name)FeatureTests" }
    public var exampleTarget: String { "\(name)FeatureExample" }
}

extension DomainModule {
    public var name: String { String(describing: self) }
    public var path: String { "Projects/Domain/\(name)" }

    public var interfaceTarget: String { "\(name)DomainInterface" }
    /// PreviewSupport는 도메인이 아니라 프리뷰용 Mock 묶음이라 `Domain` 접미사를 붙이지 않는다.
    /// 붙이면 Feature가 Domain 구현을 import하는지 검사하는 CI 규칙에 걸린다.
    public var implementationTarget: String { name == "PreviewSupport" ? name : "\(name)Domain" }
    public var testingTarget: String { "\(name)DomainTesting" }
    public var testsTarget: String { "\(name)DomainTests" }
}

extension CoreModule {
    public var name: String { String(describing: self) }
    public var path: String { "Projects/Core/\(name)" }

    public var interfaceTarget: String { "\(name)Interface" }
    public var implementationTarget: String { name }
    public var testingTarget: String { "\(name)Testing" }
    public var testsTarget: String { "\(name)Tests" }
}

extension SharedModule {
    public var name: String { String(describing: self) }
    public var path: String { "Projects/Shared/\(name)" }

    /// `Foundation`은 Apple 프레임워크와 이름이 겹쳐 `RephotoFoundation`으로 만든다.
    public var implementationTarget: String { name == "Foundation" ? "RephotoFoundation" : name }
}

// MARK: - 의존성 헬퍼

extension TargetDependency {

    // MARK: Feature

    public static func feature(interface module: FeatureModule) -> TargetDependency {
        .project(target: module.interfaceTarget, path: .relativeToRoot(module.path))
    }

    public static func feature(implementation module: FeatureModule) -> TargetDependency {
        .project(target: module.implementationTarget, path: .relativeToRoot(module.path))
    }

    public static func feature(testing module: FeatureModule) -> TargetDependency {
        .project(target: module.testingTarget, path: .relativeToRoot(module.path))
    }

    // MARK: Domain

    public static func domain(interface module: DomainModule) -> TargetDependency {
        .project(target: module.interfaceTarget, path: .relativeToRoot(module.path))
    }

    public static func domain(implementation module: DomainModule) -> TargetDependency {
        .project(target: module.implementationTarget, path: .relativeToRoot(module.path))
    }

    public static func domain(testing module: DomainModule) -> TargetDependency {
        .project(target: module.testingTarget, path: .relativeToRoot(module.path))
    }

    // MARK: Core

    public static func core(interface module: CoreModule) -> TargetDependency {
        .project(target: module.interfaceTarget, path: .relativeToRoot(module.path))
    }

    public static func core(implementation module: CoreModule) -> TargetDependency {
        .project(target: module.implementationTarget, path: .relativeToRoot(module.path))
    }

    public static func core(testing module: CoreModule) -> TargetDependency {
        .project(target: module.testingTarget, path: .relativeToRoot(module.path))
    }

    // MARK: Shared

    public static func shared(_ module: SharedModule) -> TargetDependency {
        .project(target: module.implementationTarget, path: .relativeToRoot(module.path))
    }
}
