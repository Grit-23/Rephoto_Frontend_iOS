// swift-tools-version: 6.0
//
//  Package.swift
//  Rephoto
//
//  Created by Doyeon Kim on 10/30/26.
//

import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    /// 외부 패키지도 모듈과 같은 staticFramework로 링크한다 (기본값).
    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

/// 기존 xcodeproj의 Package.resolved와 같은 버전으로 고정한다.
let package = Package(
    name: "Rephoto",
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory", exact: "2.5.3"),
        .package(url: "https://github.com/kean/Nuke", exact: "12.8.0"),
    ]
)
