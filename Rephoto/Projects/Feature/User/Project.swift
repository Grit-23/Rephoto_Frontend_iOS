import ProjectDescription
import DependencyPlugin

// Interface는 다른 Feature가 이 Feature의 화면을 열어야 할 때만 둔다.
// 필요해지면 Interface/ 폴더를 만들고 hasInterface: true로 바꾼다.
let project = Project.feature(
    .User,
    hasInterface: false,
    hasTests: true,
    hasExample: true,
    implementationDependencies: [
        .domain(interface: .User),
        .shared(.Foundation),
        .shared(.DesignSystem),
    ],
    testsDependencies: [
        .domain(interface: .User),
        .domain(testing: .User),
        .shared(.Foundation),
    ],
    exampleDependencies: [
        .domain(interface: .User),
        .domain(implementation: .User),
        .domain(implementation: .PreviewSupport),
    ]
)
