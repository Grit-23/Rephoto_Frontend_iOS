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
    /// 앱과 같은 최소 버전으로 생성해 최신 Xcode의 지원 범위를 맞춘다.
    /// 리소스 번들 타깃(Factory의 PrivacyInfo)에는 이 설정이 닿지 않아 generate 뒤
    /// `Scripts/patch-package-deployment-target`가 마저 맞춘다.
    let packageSettings = PackageSettings(
        productTypes: [:],
        targetSettings: [
            "Factory": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"]),
            "Nuke": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"]),
            "NukeUI": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"]),
        ]
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
