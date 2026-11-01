//
//  core.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//
//  make module type=core name=<Name> → Projects/Core/<Name>
//  Interface가 필요하면 Interface 폴더를 만들고 hasInterface: true로 바꾼다.
//

import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Core 모듈 (Sources · Testing · Tests)",
    attributes: [name],
    items: [
        .string(
            path: "Project.swift",
            contents: """
            import ProjectDescription
            import DependencyPlugin

            // 의존성은 실제로 import할 때 추가한다 (예: implementationDependencies: [.shared(.Foundation)]).
            // 선언만 하고 import하지 않으면 tuist inspect dependencies가 실패한다.
            let project = Project.core(.\(name))

            """
        ),
        .string(
            path: "Sources/\(name).swift",
            contents: """
            // \(name) — Feature · Domain이 공유하는 인프라를 둔다.

            """
        ),
        .string(
            path: "Testing/Sources/\(name)Testing.swift",
            contents: """
            // \(name)Testing — 수제 테스트 더블을 둔다.
            // mockolo Mock은 make mock이 Testing/Generated/Mocks.swift에 만든다.

            """
        ),
        .string(
            path: "Tests/\(name)Tests.swift",
            contents: """
            import Testing
            import \(name)Testing
            @testable import \(name)

            @Suite("\(name)")
            struct \(name)Tests {}

            """
        ),
    ]
)
