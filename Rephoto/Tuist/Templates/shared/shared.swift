//
//  shared.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//
//  make module type=shared name=<Name> → Projects/Shared/<Name>
//

import ProjectDescription

let name: Template.Attribute = .required("name")

let template = Template(
    description: "Shared 모듈 (Sources)",
    attributes: [name],
    items: [
        .string(
            path: "Project.swift",
            contents: """
            import ProjectDescription
            import DependencyPlugin

            let project = Project.shared(.\(name))

            """
        ),
        .string(
            path: "Sources/\(name).swift",
            contents: """
            // \(name) — 모든 계층이 쓰는 공용 코드를 둔다.

            """
        ),
    ]
)
