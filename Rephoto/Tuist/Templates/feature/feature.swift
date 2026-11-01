//
//  feature.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//
//  make module type=feature name=<Name> → Projects/Feature/<Name>
//

import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Feature 모듈 (Interface · Sources · Tests · Example)",
    attributes: [name],
    items: [
        .string(
            path: "Project.swift",
            contents: """
            import ProjectDescription
            import DependencyPlugin

            let project = Project.feature(
                .\(name),
                hasInterface: true,
                hasTests: true,
                hasExample: true,
                interfaceDependencies: [],
                implementationDependencies: [],
                // Example 앱에 주입할 Mock (예: .domain(implementation: .PreviewSupport))
                exampleDependencies: []
            )

            """
        ),
        .string(
            path: "Example/Sources/\(name)FeatureExampleApp.swift",
            contents: """
            import SwiftUI
            import \(name)Feature

            /// \(name)Feature만 단독으로 띄워 확인하는 앱.
            /// 루트 화면에 PreviewSupport Mock을 주입해 서버 없이 동작을 본다.
            @main
            struct \(name)FeatureExampleApp: App {
                var body: some Scene {
                    WindowGroup {
                        Text("\(name)Feature Example")
                    }
                }
            }

            """
        ),
        .string(
            path: "Interface/\(name)FeatureInterface.swift",
            contents: """
            // \(name)FeatureInterface — 다른 Feature가 참조하는 화면 생성 프로토콜을 둔다.

            """
        ),
        .string(
            path: "Sources/\(name)Feature.swift",
            contents: """
            // \(name)Feature — 화면 · ViewModel과 Interface 구현을 둔다.

            """
        ),
        .string(
            path: "Tests/\(name)FeatureTests.swift",
            contents: """
            import Testing
            @testable import \(name)Feature

            @Suite("\(name)Feature")
            struct \(name)FeatureTests {}

            """
        ),
    ]
)
