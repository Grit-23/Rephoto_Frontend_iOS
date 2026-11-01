//
//  Plugin.swift
//  DependencyPlugin
//
//  Created by Doyeon Kim on 10/30/26.
//

import ProjectDescription

/// 모듈 enum · 의존성 헬퍼 · 계층별 Project 공장을 매니페스트에 제공한다.
/// 매니페스트에서 `import DependencyPlugin`으로 쓴다.
let plugin = Plugin(name: "DependencyPlugin")
