import ProjectDescription
import DependencyPlugin

/// Home 화면 — 사진 목록 · 업로드 · 상세(태그 · 설명 · 지도) · 민감 사진.
/// Domain은 Interface만 보고, UseCase 조립은 `HomeUseCaseProviderProtocol` 구현을 init으로 받는다.
/// Interface는 Search가 사진 상세를 여는 `PhotoDetailBuilding`만 둔다.
let project = Project.feature(
    .Home,
    hasInterface: true,
    hasTests: true,
    hasExample: true,
    interfaceDependencies: [
        .domain(interface: .Photo),
    ],
    implementationDependencies: [
        .domain(interface: .Photo),
        .domain(interface: .Tag),
        .shared(.Foundation),
        .shared(.DesignSystem),
        .external(name: "NukeUI"),
    ],
    testsDependencies: [
        .domain(interface: .Photo),
        .domain(interface: .Tag),
        .domain(testing: .Photo),
        .domain(testing: .Tag),
        .shared(.Foundation),
        .shared(.DesignSystem),
    ],
    // Example은 서버 대신 PreviewSupport의 메모리 Repository와 실제 UseCase로 조립한다.
    exampleDependencies: [
        .domain(interface: .Photo),
        .domain(interface: .Tag),
        .domain(implementation: .Photo),
        .domain(implementation: .Tag),
        .domain(implementation: .PreviewSupport),
        .shared(.DesignSystem),
    ]
)
