import ProjectDescription
import DependencyPlugin

/// Search 화면 — 앨범 목록 · 앨범 사진 · 검색.
/// Domain은 Interface만 보고, 사진 상세는 `HomeFeatureInterface`의 팩토리를 init으로 받아 연다.
let project = Project.feature(
    .Search,
    hasInterface: false,
    hasTests: true,
    hasExample: true,
    implementationDependencies: [
        .domain(interface: .Album),
        .domain(interface: .Photo),
        .feature(interface: .Home),
        .shared(.Foundation),
        .shared(.DesignSystem),
    ],
    testsDependencies: [
        .domain(interface: .Album),
        .domain(interface: .Photo),
        .domain(testing: .Album),
        .domain(testing: .Photo),
        .feature(interface: .Home),
        .shared(.Foundation),
        .shared(.DesignSystem),
    ],
    exampleDependencies: [
        .domain(interface: .Album),
        .domain(interface: .Photo),
        .domain(implementation: .Album),
        .domain(implementation: .Photo),
        .domain(implementation: .PreviewSupport),
        .feature(interface: .Home),
        .shared(.DesignSystem),
    ]
)
