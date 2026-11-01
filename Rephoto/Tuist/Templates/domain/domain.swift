//
//  domain.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//
//  make module type=domain name=<Name> → Projects/Domain/<Name>
//

import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Domain 모듈 (Interface · Sources · Testing · Tests)",
    attributes: [name],
    items: [
        .string(
            path: "Project.swift",
            contents: """
            import ProjectDescription
            import DependencyPlugin

            let project = Project.domain(
                .\(name),
                interfaceDependencies: [
                    .shared(.Foundation),
                ],
                implementationDependencies: []
            )

            """
        ),
        .string(
            path: "Interface/\(name)DomainInterface.swift",
            contents: """
            // \(name)DomainInterface — 엔티티와 UseCase · Repository 프로토콜을 둔다.
            // Mock이 필요한 프로토콜에는 `/// @mockable`을 붙인다.

            """
        ),
        .string(
            path: "Sources/\(name)Domain.swift",
            contents: """
            // \(name)Domain — UseCase · Repository 구현, DTO, API Target을 둔다.

            """
        ),
        .string(
            path: "Testing/Sources/\(name)DomainTesting.swift",
            contents: """
            // \(name)DomainTesting — 수제 테스트 더블을 둔다.
            // mockolo Mock은 make mock이 Testing/Generated/Mocks.swift에 만든다.

            """
        ),
        .string(
            path: "Tests/\(name)DomainTests.swift",
            contents: """
            import Testing
            @testable import \(name)Domain

            @Suite("\(name)Domain")
            struct \(name)DomainTests {}

            """
        ),
    ]
)
