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
    description: "Feature 모듈 (Sources · Tests · Example. Interface는 참조될 때만 추가)",
    attributes: [name],
    items: [
        .string(
            path: "Project.swift",
            contents: """
            import ProjectDescription
            import DependencyPlugin

            // Interface는 다른 Feature가 이 Feature의 화면을 열어야 할 때만 둔다.
            // 필요해지면 Interface/ 폴더를 만들고 hasInterface: true로 바꾼다.
            let project = Project.feature(
                .\(name),
                hasInterface: false,
                hasTests: true,
                hasExample: true,
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
            /// 지금은 placeholder 텍스트뿐이다. 루트 화면을 연결하고 Project.swift의
            /// exampleDependencies에 PreviewSupport를 넣어야 서버 없이 동작을 볼 수 있다.
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
            path: "Sources/\(name)Feature.swift",
            contents: """
            // \(name)Feature — 화면 · ViewModel을 둔다.
            // 다른 Feature가 이 화면을 열어야 하면 Interface/에 화면 생성 프로토콜을 두고 여기서 구현한다.

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
