//
//  Project+Module.swift
//  DependencyPlugin
//
//  Created by Doyeon Kim on 10/30/26.
//

import ProjectDescription

/// 계층별 Project 공장.
///
/// 모듈 폴더는 `Interface · Sources · Testing · Tests` 중 필요한 것만 둔다.
/// 폴더 구성과 `has*` 인자를 맞춘다 — 폴더를 지웠으면 해당 인자도 `false`로 바꾼다.
///
/// | 타깃 | 소스 | 기본 의존 |
/// | --- | --- | --- |
/// | Interface | `Interface/**` | `interfaceDependencies` |
/// | 구현 | `Sources/**` | Interface + `implementationDependencies` |
/// | Testing | `Testing/Sources/**`, `Testing/Generated/**` | Interface(없으면 구현) + `testingDependencies` |
/// | Tests | `Tests/**` | 구현 + Testing + `testsDependencies` |
/// | Example (Feature만) | `Example/Sources/**` | 구현 + `exampleDependencies` |
extension Project {

    /// Feature 모듈. 기본 격리는 `MainActor`.
    ///
    /// Feature는 Example 앱을 기본으로 갖는다. 앱 전체 없이 이 Feature만 띄워
    /// 동작을 확인한 뒤 PR을 올린다 (Mock은 `exampleDependencies`로 주입).
    ///
    /// Interface는 다른 Feature가 이 Feature의 화면을 열어야 할 때만 둔다.
    /// 그래서 기본값이 `false`다 — 필요할 때 `Interface/` 폴더를 만들고 `true`로 바꾼다.
    public static func feature(
        _ module: FeatureModule,
        hasInterface: Bool = false,
        hasTesting: Bool = false,
        hasTests: Bool = false,
        hasExample: Bool = true,
        interfaceDependencies: [TargetDependency] = [],
        implementationDependencies: [TargetDependency] = [],
        testingDependencies: [TargetDependency] = [],
        testsDependencies: [TargetDependency] = [],
        exampleDependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil,
        isolation: ActorIsolation = .mainActor
    ) -> Project {
        makeModule(
            targets: ModuleTargets(
                interface: module.interfaceTarget,
                implementation: module.implementationTarget,
                testing: module.testingTarget,
                tests: module.testsTarget,
                example: hasExample ? module.exampleTarget : nil
            ),
            hasInterface: hasInterface,
            hasTesting: hasTesting,
            hasTests: hasTests,
            interfaceDependencies: interfaceDependencies,
            implementationDependencies: implementationDependencies,
            testingDependencies: testingDependencies,
            testsDependencies: testsDependencies,
            exampleDependencies: exampleDependencies,
            resources: resources,
            isolation: isolation
        )
    }

    /// Domain 모듈. 기본 격리는 `nonisolated`.
    public static func domain(
        _ module: DomainModule,
        hasInterface: Bool = true,
        hasTesting: Bool = true,
        hasTests: Bool = true,
        interfaceDependencies: [TargetDependency] = [],
        implementationDependencies: [TargetDependency] = [],
        testingDependencies: [TargetDependency] = [],
        testsDependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil,
        isolation: ActorIsolation = .nonisolated
    ) -> Project {
        makeModule(
            targets: ModuleTargets(
                interface: module.interfaceTarget,
                implementation: module.implementationTarget,
                testing: module.testingTarget,
                tests: module.testsTarget
            ),
            hasInterface: hasInterface,
            hasTesting: hasTesting,
            hasTests: hasTests,
            interfaceDependencies: interfaceDependencies,
            implementationDependencies: implementationDependencies,
            testingDependencies: testingDependencies,
            testsDependencies: testsDependencies,
            resources: resources,
            isolation: isolation
        )
    }

    /// Core 모듈. 기본 격리는 `nonisolated`.
    ///
    /// Tests는 호스트 앱 없이 돈다. 호스트 앱을 붙이면 테스트 실패 때 xcodebuild가 시뮬레이터 진단
    /// 수집에 들어가 10분 가까이 멈추므로, Keychain처럼 앱 identity가 필요한 코드는 주입으로 떼어 낸다.
    public static func core(
        _ module: CoreModule,
        hasInterface: Bool = false,
        hasTesting: Bool = true,
        hasTests: Bool = true,
        interfaceDependencies: [TargetDependency] = [],
        implementationDependencies: [TargetDependency] = [],
        testingDependencies: [TargetDependency] = [],
        testsDependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil,
        isolation: ActorIsolation = .nonisolated,
        settings: SettingsDictionary = [:]
    ) -> Project {
        makeModule(
            targets: ModuleTargets(
                interface: module.interfaceTarget,
                implementation: module.implementationTarget,
                testing: module.testingTarget,
                tests: module.testsTarget
            ),
            hasInterface: hasInterface,
            hasTesting: hasTesting,
            hasTests: hasTests,
            interfaceDependencies: interfaceDependencies,
            implementationDependencies: implementationDependencies,
            testingDependencies: testingDependencies,
            testsDependencies: testsDependencies,
            resources: resources,
            isolation: isolation,
            settings: settings
        )
    }

    /// Shared 모듈. 구현 타깃과 (필요하면) Tests만 둔다. 기본 격리는 `nonisolated`.
    ///
    /// 프로토콜이 없는 계층이라 Interface · Testing은 만들지 않는다.
    /// DesignSystem처럼 UI를 담는 모듈은 `isolation: .mainActor`로 넘긴다.
    public static func shared(
        _ module: SharedModule,
        hasTests: Bool = false,
        dependencies: [TargetDependency] = [],
        testsDependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil,
        isolation: ActorIsolation = .nonisolated,
        settings: SettingsDictionary = [:]
    ) -> Project {
        let name = module.implementationTarget
        return makeModule(
            targets: ModuleTargets(
                interface: "\(name)Interface",
                implementation: name,
                testing: "\(name)Testing",
                tests: "\(name)Tests"
            ),
            hasInterface: false,
            hasTesting: false,
            hasTests: hasTests,
            interfaceDependencies: [],
            implementationDependencies: dependencies,
            testingDependencies: [],
            testsDependencies: testsDependencies,
            resources: resources,
            isolation: isolation,
            settings: settings
        )
    }
}

// MARK: - 공통 조립

private struct ModuleTargets {
    let interface: String
    let implementation: String
    let testing: String
    let tests: String
    /// Example 앱 타깃 이름. `nil`이면 만들지 않는다 (Feature만 쓴다).
    var example: String? = nil
}

extension Project {

    /// 프로젝트 이름은 구현 타깃 이름을 쓴다.
    /// Feature/User와 Domain/User처럼 폴더 이름이 겹쳐도 워크스페이스 안에서 구분된다.
    fileprivate static func makeModule(
        targets: ModuleTargets,
        hasInterface: Bool,
        hasTesting: Bool,
        hasTests: Bool,
        interfaceDependencies: [TargetDependency],
        implementationDependencies: [TargetDependency],
        testingDependencies: [TargetDependency],
        testsDependencies: [TargetDependency],
        exampleDependencies: [TargetDependency] = [],
        resources: ResourceFileElements?,
        isolation: ActorIsolation,
        settings: SettingsDictionary = [:]
    ) -> Project {
        var result: [Target] = []

        if hasInterface {
            result.append(
                framework(
                    name: targets.interface,
                    sources: ["Interface/**"],
                    dependencies: interfaceDependencies,
                    isolation: isolation
                )
            )
        }

        result.append(
            framework(
                name: targets.implementation,
                sources: ["Sources/**"],
                resources: resources,
                dependencies: (hasInterface ? [.target(name: targets.interface)] : [])
                    + implementationDependencies,
                isolation: isolation
            )
        )

        if hasTesting {
            // Testing은 Interface를 대상으로 Mock을 만든다. Interface가 없는 모듈은 구현을 본다.
            let testedTarget = hasInterface ? targets.interface : targets.implementation
            result.append(
                framework(
                    name: targets.testing,
                    sources: ["Testing/Sources/**", "Testing/Generated/**"],
                    dependencies: [.target(name: testedTarget)] + testingDependencies,
                    isolation: isolation
                )
            )
        }

        if hasTests {
            result.append(
                .target(
                    name: targets.tests,
                    destinations: rephotoDestinations,
                    product: .unitTests,
                    bundleId: bundleId(targets.tests),
                    deploymentTargets: rephotoDeploymentTargets,
                    sources: ["Tests/**"],
                    dependencies: [.target(name: targets.implementation)]
                        + (hasTesting ? [.target(name: targets.testing)] : [])
                        + testsDependencies,
                    settings: .settings(base: isolationSettings(isolation))
                )
            )
        }

        if let example = targets.example {
            // Feature만 단독으로 띄우는 앱. 서버 대신 PreviewSupport Mock을 주입한다.
            result.append(
                .target(
                    name: example,
                    destinations: rephotoDestinations,
                    product: .app,
                    bundleId: bundleId(example),
                    deploymentTargets: rephotoDeploymentTargets,
                    infoPlist: .extendingDefault(with: [
                        "UILaunchScreen": [:],
                        "NSPhotoLibraryUsageDescription": "사진권한",
                        "NSFaceIDUsageDescription": "숨겨진 민감한 사진을 보려면 Face ID 인증이 필요해요.",
                    ]),
                    sources: ["Example/Sources/**"],
                    dependencies: [.target(name: targets.implementation)] + exampleDependencies,
                    settings: .settings(base: isolationSettings(.mainActor))
                )
            )
        }

        return Project(
            name: targets.implementation,
            settings: .settings(base: rephotoBaseSettings.merging(settings)),
            targets: result
        )
    }

    private static func framework(
        name: String,
        sources: SourceFilesList,
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency],
        isolation: ActorIsolation
    ) -> Target {
        .target(
            name: name,
            destinations: rephotoDestinations,
            product: .staticFramework,
            bundleId: bundleId(name),
            deploymentTargets: rephotoDeploymentTargets,
            sources: sources,
            resources: resources,
            dependencies: dependencies,
            settings: .settings(base: isolationSettings(isolation))
        )
    }

    private static func bundleId(_ target: String) -> String {
        "com.dodle.rephoto.\(target)"
    }
}
