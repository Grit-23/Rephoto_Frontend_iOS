//
//  Tuist.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//

import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        plugins: [
            .local(path: .relativeToRoot("Plugins/DependencyPlugin")),
        ]
    )
)
